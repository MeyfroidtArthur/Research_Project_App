import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription? _remoteCandidatesSubscription;
  StreamSubscription? _answerSubscription;

  final ValueNotifier<String> connectionState = ValueNotifier<String>('New');
  final ValueNotifier<String> iceState = ValueNotifier<String>('New');

  // Configuration for STUN/TURN servers
  // Ideally, use your own TURN servers for production.
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': false,
  };

  Future<void> initialize() async {
    _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
  }

  // As the Caller (Victim/Slachtoffer)
  MediaStream? _remoteStream;

  // ... (startCall implementation remains similar, but update onTrack)

  Future<void> startCall(DocumentReference callRef) async {
    // Clean up any existing call session first to prevent duplicate listeners
    await _answerSubscription?.cancel();
    await _remoteCandidatesSubscription?.cancel();
    _peerConnection?.close(); // Don't dispose local stream, we reuse it

    if (_localStream == null) {
      await initialize();
    }

    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection!.onIceConnectionState = (state) {
      print('❄️ ICE Connection State: $state');
      iceState.value = state.toString();
    };

    _peerConnection!.onConnectionState = (state) {
      print('🔗 Peer Connection State: $state');
      connectionState.value = state.toString();
    };

    _peerConnection!.onSignalingState = (state) {
      print('🚦 Signaling State: $state');
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('📤 Sending ICE candidate: ${candidate.candidate}');
      callRef.collection('callerCandidates').add(candidate.toMap());
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print(
          '🎧 Track received: ${event.track.kind}, enabled: ${event.track.enabled}');
      if (event.track.kind == 'audio') {
        _remoteStream = event.streams[0];
        _remoteStream!.getAudioTracks().first.enabled = true;
        // Force speakerphone
        Future.delayed(Duration(milliseconds: 500), () {
          Helper.setSpeakerphoneOn(true);
          print('📢 Forced speakerphone ON');
        });
      }
    };

    _localStream!.getTracks().forEach((track) {
      print('🎤 Adding local track: ${track.kind}');
      _peerConnection!.addTrack(track, _localStream!);
    });

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await callRef.update({
      'offer': {
        'sdp': offer.sdp,
        'type': offer.type,
      }
    });

    // Listen for Answer
    _answerSubscription = callRef.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('answer') && _peerConnection != null) {
          final answerData = data['answer'];
          final String? sdp = answerData['sdp'];
          final String? type = answerData['type'];

          if (sdp != null && type != null) {
            // Check if we already have a remote description to avoid re-setting
            if (await _peerConnection!.getRemoteDescription() == null) {
              RTCSessionDescription answer = RTCSessionDescription(sdp, type);
              await _peerConnection!.setRemoteDescription(answer);
            }
          }
        }
      }
    });

    // Listen for Remote Ice Candidates (calleeCandidates)
    _remoteCandidatesSubscription =
        callRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            _peerConnection!.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
            print('📥 Added remote candidate: ${data['candidate']}');
          }
        }
      }
    });
  }

  // As the Callee (Dispatcher/Hulpverlener)
  Future<void> answerCall(DocumentReference callRef) async {
    // Clean up any existing call session first
    await _answerSubscription?.cancel();
    await _remoteCandidatesSubscription?.cancel();
    _peerConnection?.close();

    if (_localStream == null) {
      await initialize();
    }

    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      callRef.collection('calleeCandidates').add(candidate.toMap());
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      event.streams[0].getAudioTracks().first.enabled = true;
    };

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Get the offer
    final snapshot = await callRef.get();
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('offer')) {
      final offerData = data['offer'];
      final String? sdp = offerData['sdp'];
      final String? type = offerData['type'];

      if (sdp != null && type != null) {
        RTCSessionDescription offer = RTCSessionDescription(sdp, type);
        await _peerConnection!.setRemoteDescription(offer);

        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        await callRef.update({
          'answer': {
            'sdp': answer.sdp,
            'type': answer.type,
          }
        });
      }
    }

    // Listen for Remote Ice Candidates (callerCandidates)
    _remoteCandidatesSubscription =
        callRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            _peerConnection!.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }
        }
      }
    });
  }

  Future<void> hangUp(DocumentReference callRef) async {
    await _localStream?.dispose();
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    await _remoteCandidatesSubscription?.cancel();
    await _answerSubscription?.cancel();

    // Clean up signaling? Or let the backend handle it.
    // For now we just close the local connection.
  }

  bool isAudioEnabled() {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      return _localStream!.getAudioTracks().first.enabled;
    }
    return false;
  }

  void toggleMute() {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      bool enabled = _localStream!.getAudioTracks().first.enabled;
      _localStream!.getAudioTracks().first.enabled = !enabled;
    }
  }

  void toggleSpeaker() {
    // Basic toggle, though we might need track state tracking
    // For now assumes it starts as true.
    // Helper.setSpeakerphoneOn(!currentStatus);
    // This is stateful on the native side, but ideally we track it.
    // Let's just expose setSpeakerphone
  }

  Future<void> setSpeaker(bool enabled) async {
    await Helper.setSpeakerphoneOn(enabled);
  }
}
