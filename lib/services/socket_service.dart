import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Initialize socket service
  Future<void> initialize() async {
    // Socket will be initialized when connecting
  }

  // Connect to WebSocket server
  Future<void> connect() async {
    try {
      _socket = IO.io('http://localhost:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {
          // Add authentication if needed
        },
      });

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      print('Failed to connect to socket: $e');
    }
  }

  // Setup socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('Socket connected');
      _isConnected = true;
      _messageController.add({
        'type': 'connection_status',
        'status': 'connected',
      });
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
      _messageController.add({
        'type': 'connection_status',
        'status': 'disconnected',
      });
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
      _isConnected = false;
      _messageController.add({
        'type': 'connection_error',
        'error': error.toString(),
      });
    });

    // Document processing updates
    _socket!.on('processing-update', (data) {
      _messageController.add({
        'type': 'processing_update',
        'data': data,
      });
    });

    // Job status changes
    _socket!.on('job-status-change', (data) {
      _messageController.add({
        'type': 'job_status_change',
        'data': data,
      });
    });

    // General notifications
    _socket!.on('notification', (data) {
      _messageController.add({
        'type': 'notification',
        'data': data,
      });
    });

    // Document updates
    _socket!.on('document-update', (data) {
      _messageController.add({
        'type': 'document_update',
        'data': data,
      });
    });

    // Question generation updates
    _socket!.on('question-generation-update', (data) {
      _messageController.add({
        'type': 'question_generation_update',
        'data': data,
      });
    });

    // User activity updates
    _socket!.on('user-activity', (data) {
      _messageController.add({
        'type': 'user_activity',
        'data': data,
      });
    });

    // Error events
    _socket!.on('error', (data) {
      _messageController.add({
        'type': 'error',
        'data': data,
      });
    });
  }

  // Join a specific document room for real-time updates
  void joinDocument(String documentId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join-document', {'documentId': documentId});
    }
  }

  // Leave a document room
  void leaveDocument(String documentId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave-document', {'documentId': documentId});
    }
  }

  // Join user's personal room
  void joinUserRoom(String userId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join-user-room', {'userId': userId});
    }
  }

  // Send a message to the server
  void sendMessage(String event, Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    }
  }

  // Request document processing status
  void requestDocumentStatus(String documentId) {
    sendMessage('request-document-status', {'documentId': documentId});
  }

  // Request job status
  void requestJobStatus(String jobId) {
    sendMessage('request-job-status', {'jobId': jobId});
  }

  // Subscribe to document updates
  void subscribeToDocument(String documentId) {
    sendMessage('subscribe-document', {'documentId': documentId});
  }

  // Unsubscribe from document updates
  void unsubscribeFromDocument(String documentId) {
    sendMessage('unsubscribe-document', {'documentId': documentId});
  }

  // Send typing indicator
  void sendTypingIndicator(String documentId, bool isTyping) {
    sendMessage('typing-indicator', {
      'documentId': documentId,
      'isTyping': isTyping,
    });
  }

  // Send document comment
  void sendDocumentComment(String documentId, String comment) {
    sendMessage('document-comment', {
      'documentId': documentId,
      'comment': comment,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Request real-time collaboration data
  void requestCollaborationData(String documentId) {
    sendMessage('request-collaboration-data', {'documentId': documentId});
  }

  // Send collaboration cursor position
  void sendCursorPosition(String documentId, Map<String, dynamic> position) {
    sendMessage('cursor-position', {
      'documentId': documentId,
      'position': position,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send document selection
  void sendDocumentSelection(String documentId, Map<String, dynamic> selection) {
    sendMessage('document-selection', {
      'documentId': documentId,
      'selection': selection,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Listen to specific event types
  Stream<Map<String, dynamic>> listenToEvent(String eventType) {
    return _messageController.stream.where((message) => 
        message['type'] == eventType);
  }

  // Listen to document updates
  Stream<Map<String, dynamic>> get documentUpdateStream => 
      listenToEvent('document_update');

  // Listen to processing updates
  Stream<Map<String, dynamic>> get processingUpdateStream => 
      listenToEvent('processing_update');

  // Listen to job status changes
  Stream<Map<String, dynamic>> get jobStatusStream => 
      listenToEvent('job_status_change');

  // Listen to notifications
  Stream<Map<String, dynamic>> get notificationStream => 
      listenToEvent('notification');

  // Listen to connection status
  Stream<Map<String, dynamic>> get connectionStatusStream => 
      listenToEvent('connection_status');

  // Check connection status
  bool get connectionStatus => _isConnected;

  // Reconnect to socket
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(Duration(seconds: 2));
    await connect();
  }

  // Disconnect from socket
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
  }

  // Add custom event listener
  void addCustomEventListener(String event, Function(dynamic) handler) {
    if (_socket != null) {
      _socket!.on(event, handler);
    }
  }

  // Remove custom event listener
  void removeCustomEventListener(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  // Get socket instance (for advanced usage)
  IO.Socket? get socket => _socket;

  // Check if socket is ready
  bool get isReady => _socket != null && _isConnected;

  // Send heartbeat to keep connection alive
  void sendHeartbeat() {
    if (_isReady) {
      _socket!.emit('heartbeat', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Start heartbeat timer
  Timer? _heartbeatTimer;
  void startHeartbeat({Duration interval = Duration(seconds: 30)}) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(interval, (_) {
      sendHeartbeat();
    });
  }

  // Stop heartbeat timer
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
