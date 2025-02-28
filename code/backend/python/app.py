from flask import Flask
from flask_socketio import SocketIO
from flask_cors import CORS
from service.message_service import MessageService

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")
message_service = MessageService(socketio)

@socketio.on('connect', namespace='/ws/chat')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect', namespace='/ws/chat')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('message', namespace='/ws/chat')
def handle_message(data):
    response = message_service.handle_message(data)
    emit('response', response)

if __name__ == '__main__':
    socketio.run(app, debug=True, port=5000) 