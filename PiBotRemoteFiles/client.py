import socket
s = socket.socket()
s.connect(('pibot.local',2000))
s.setblocking(0)
print("connected")
