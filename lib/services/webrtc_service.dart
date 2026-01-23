import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // Getter to access local stream for mute/unmute
  MediaStream? get localStream => _localStream;

  Future<void> startCall({
    required String voornaam,
    required String achternaam,
    DocumentReference? callDocRef,
    required Function(MediaStream) onLocalStream,
    required Function(MediaStream) onRemoteStream,
  }) async {
    // 1. Create Peer Connection
    final config = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    };
    _peerConnection = await createPeerConnection(config);

    // 2. Create the Firestore Document Reference (or use existing)
    callDocRef ??= FirebaseFirestore.instance.collection('connection').doc();

    // 3. Handle ICE Candidates (Caller Candidates)
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      callDocRef!.collection('callerCandidates').add(candidate.toMap());
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        onRemoteStream(event.streams[0]);
      }
    };

    // 4. Get User Media (Audio only)
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    onLocalStream(_localStream!);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // 5. Create Offer
    await _createAndSendOffer(callDocRef, voornaam, achternaam);

    print("Call started! Connection ID: ${callDocRef.id}");

    // 7. Listen for Answer (from Dispatch Console)
    callDocRef.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // Check if answered
        if (data.containsKey('answer') &&
            _peerConnection!.signalingState ==
                RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          var answerData = data['answer'];
          var answer =
              RTCSessionDescription(answerData['sdp'], answerData['type']);
          await _peerConnection!.setRemoteDescription(answer);
        }
      }
    });

    // 8. Listen for Callee Candidates (from Dispatch Console)
    callDocRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          _peerConnection!.addCandidate(RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ));
        }
      }
    });
  }

  Future<void> _createAndSendOffer(
      DocumentReference callDocRef, String voornaam, String achternaam) async {
    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await _peerConnection!.setLocalDescription(offer);

    await callDocRef.set({
      'offer': {
        'sdp': offer.sdp,
        'type': offer.type,
      },
      // Do NOT overwrite status here; dispatcher controls status transitions.
      'voornaam': voornaam,
      'achternaam': achternaam,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> hangUp() async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      await _localStream!.dispose();
      _localStream = null;
    }
    if (_peerConnection != null) {
      _peerConnection!.close();
      _peerConnection = null;
    }
  }

  /// Toggle microphone mute/unmute
  void setMicrophoneMuted(bool muted) {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = !muted;
      }
      print('🎤 Microphone ${muted ? "muted" : "unmuted"}');
    }
  }
}

/// ------------------------------------------------------------
/// FIREBASE SENDER (Firestore-based signaling)
/// ------------------------------------------------------------
/// This class provides a simplified WebRTC sender that uses
/// Firestore for signaling instead of WebSockets.
/// Connection data is stored in the 'connection' collection.
class FirebaseSender {
  late final RTCPeerConnection _pc;
  MediaStream? _localStream;
  DocumentReference? _connectionDoc;
  StreamSubscription<DocumentSnapshot>? _answerSubscription;
  StreamSubscription<QuerySnapshot>? _candidateSubscription;

  /// Start the WebRTC connection (Audio only)
  /// [connectionId] - Optional custom connection ID, if null a new document will be created
  /// [enableAudio] - Whether to enable audio (default: true)
  Future<String> start({
    String? connectionId,
    bool enableAudio = true,
  }) async {
    // 1. Create peer connection
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    // 2. Create or use existing Firestore document reference
    if (connectionId != null) {
      _connectionDoc =
          FirebaseFirestore.instance.collection('connection').doc(connectionId);
    } else {
      _connectionDoc =
          FirebaseFirestore.instance.collection('connection').doc();
    }

    // 3. Handle ICE candidates
    _pc.onIceCandidate = (candidate) {
      _connectionDoc!.collection('callerCandidates').add(candidate.toMap());
    };

    // 4. Get user media (Audio only)
    final mediaConstraints = {
      'audio': enableAudio
          ? {
              'echoCancellation': true,
              'noiseSuppression': true,
              'autoGainControl': true,
            }
          : false,
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // 5. Add tracks to peer connection
    for (final track in _localStream!.getTracks()) {
      await _pc.addTrack(track, _localStream!);
    }

    // 6. Create offer
    final offer = await _pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await _pc.setLocalDescription(offer);

    // 7. Save offer to Firestore
    await _connectionDoc!.set({
      'offer': {
        'sdp': offer.sdp,
        'type': offer.type,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 8. Listen for answer
    _answerSubscription = _connectionDoc!.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      if (data.containsKey('answer')) {
        final answerData = data['answer'] as Map<String, dynamic>;
        await _pc.setRemoteDescription(
          RTCSessionDescription(answerData['sdp'], answerData['type']),
        );
      }
    });

    // 9. Listen for remote ICE candidates
    _candidateSubscription = _connectionDoc!
        .collection('calleeCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _pc.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return _connectionDoc!.id;
  }

  /// Get the local media stream
  MediaStream? get localStream => _localStream;

  /// Get the peer connection
  RTCPeerConnection? get peerConnection => _pc;

  /// Stop the connection and clean up resources
  Future<void> stop() async {
    await _localStream?.dispose();
    await _pc.close();
    await _answerSubscription?.cancel();
    await _candidateSubscription?.cancel();
  }
}

/// ------------------------------------------------------------
/// FIREBASE RECEIVER (Firestore-based signaling - Answerer)
/// ------------------------------------------------------------
/// This class handles the answerer/dispatcher side of WebRTC calls
class FirebaseReceiver {
  late final RTCPeerConnection _pc;
  MediaStream? _localStream;
  DocumentReference? _connectionDoc;
  StreamSubscription<DocumentSnapshot>? _offerSubscription;
  StreamSubscription<QuerySnapshot>? _candidateSubscription;
  bool _hasProcessedOffer = false;

  /// Answer an incoming call
  /// [connectionId] - The connection document ID to answer
  /// [onLocalStream] - Callback when local audio stream is ready
  /// [onRemoteStream] - Callback when remote audio stream is received
  Future<void> answer({
    required String connectionId,
    required Function(MediaStream) onLocalStream,
    required Function(MediaStream) onRemoteStream,
  }) async {
    print('📞 FirebaseReceiver: Starting to answer call $connectionId');

    // 1. Create peer connection
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    // 2. Get connection document
    _connectionDoc =
        FirebaseFirestore.instance.collection('connection').doc(connectionId);

    // 3. Handle ICE candidates
    _pc.onIceCandidate = (candidate) {
      print('🧊 FirebaseReceiver: Sending ICE candidate');
      _connectionDoc!.collection('calleeCandidates').add(candidate.toMap());
    };

    // 4. Handle incoming tracks (remote audio)
    _pc.onTrack = (event) {
      print('🎵 FirebaseReceiver: Received remote track');
      if (event.streams.isNotEmpty) {
        onRemoteStream(event.streams[0]);
      }
    };

    // 5. Get user media (Audio only)
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    onLocalStream(_localStream!);
    print('🎤 FirebaseReceiver: Local audio stream started');

    // 6. Add tracks to peer connection
    for (final track in _localStream!.getTracks()) {
      await _pc.addTrack(track, _localStream!);
    }

    // 7. Listen for offer and create answer
    _offerSubscription = _connectionDoc!.snapshots().listen((snapshot) async {
      if (!snapshot.exists || _hasProcessedOffer) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      if (data.containsKey('offer')) {
        _hasProcessedOffer = true;
        print('📨 FirebaseReceiver: Received offer, creating answer');

        final offerData = data['offer'] as Map<String, dynamic>;
        await _pc.setRemoteDescription(
          RTCSessionDescription(offerData['sdp'], offerData['type']),
        );

        // Create answer
        final answer = await _pc.createAnswer({
          'offerToReceiveAudio': 1,
          'offerToReceiveVideo': 0,
        });
        await _pc.setLocalDescription(answer);

        // Save answer to Firestore
        await _connectionDoc!.set({
          'answer': {
            'sdp': answer.sdp,
            'type': answer.type,
          },
        }, SetOptions(merge: true));

        print('✅ FirebaseReceiver: Answer sent to Firestore');
      }
    });

    // 8. Listen for remote ICE candidates
    _candidateSubscription = _connectionDoc!
        .collection('callerCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          print('🧊 FirebaseReceiver: Adding remote ICE candidate');
          _pc.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  /// Get the local media stream
  MediaStream? get localStream => _localStream;

  /// Get the peer connection
  RTCPeerConnection? get peerConnection => _pc;

  /// Toggle microphone mute/unmute
  void setMicrophoneMuted(bool muted) {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = !muted;
      }
      print('🎤 FirebaseReceiver: Microphone ${muted ? "muted" : "unmuted"}');
    }
  }

  /// Stop the connection and clean up resources
  Future<void> stop() async {
    await _localStream?.dispose();
    await _pc.close();
    await _offerSubscription?.cancel();
    await _candidateSubscription?.cancel();
  }
}
