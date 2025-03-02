from flask import Flask
from flask_socketio import SocketIO, emit
from flask_cors import CORS
from service.message_service import MessageService

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'  # 添加密钥
CORS(app, resources={r"/*": {"origins": "*"}})

socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    async_mode=None  # 让 Flask-SocketIO 自动选择最佳模式
)
message_service = MessageService(socketio)

@socketio.on('connect')
def handle_connect():
    print('Client connected')
    # emit('response', {'answer': '您好！我是智能助手，请问有什么可以帮您？'})

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('message')
def handle_message(data):
    print('Received message:', data)
    response = message_service.handle_message(data)
    print('Sending response:', response)
    # 确保响应被发送回客户端
    emit('response', response)

if __name__ == '__main__':
    print('Starting Socket.IO server...')
    socketio.run(app, host='127.0.0.1', port=5001, debug=True) 