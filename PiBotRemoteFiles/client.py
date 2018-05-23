import socket
s = socket.socket()
s.connect(('cobalt.local',1111))
s.setblocking(0)
print("connected")
