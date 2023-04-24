import socket

def j2_environment(env):
    env.globals.update(
        hostname=socket.gethostname()
    )
    return env
