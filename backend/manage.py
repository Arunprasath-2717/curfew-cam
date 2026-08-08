#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys


def start_udp_discovery_server():
    import socket
    import threading

    def udp_listener():
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        # Some systems need SO_REUSEPORT, but SO_REUSEADDR is safer across platforms
        if hasattr(socket, 'SO_REUSEPORT'):
            try:
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
            except Exception:
                pass
        try:
            sock.bind(('', 8888))
            print("UDP Discovery listener started on port 8888")
            while True:
                try:
                    data, addr = sock.recvfrom(1024)
                    if data:
                        msg = data.decode('utf-8').strip()
                        if msg == "DISCOVER_CURFEWCAM_SERVER":
                            sock.sendto(b"CURFEWCAM_SERVER_ACK", addr)
                except Exception as e:
                    pass
        except Exception as e:
            print(f"Failed to start UDP listener: {e}")

    t = threading.Thread(target=udp_listener, daemon=True)
    t.start()


def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'src.config.settings')
    
    # Only start the discovery server if we are actually running the server
    if len(sys.argv) > 1 and sys.argv[1] == 'runserver':
        # Avoid starting multiple times if auto-reloading
        if os.environ.get('RUN_MAIN') == 'true':
            start_udp_discovery_server()
            
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()