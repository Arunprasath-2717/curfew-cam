from django.apps import AppConfig

class NotificationsConfig(AppConfig):
    name = 'apps.notifications'

    def ready(self):
        try:
            import firebase_admin
            from firebase_admin import credentials
        except ImportError:
            print("firebase_admin not installed — push notifications disabled")
            return

        from django.conf import settings
        import os
        
        # Initialize Firebase Admin if not already initialized
        if not firebase_admin._apps:
            cred_path = os.path.join(settings.BASE_DIR, 'firebase-service-account.json')
            if os.path.exists(cred_path):
                try:
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                except Exception as e:
                    print(f"Failed to initialize Firebase Admin: {e}")
            else:
                print(f"Firebase credentials not found at {cred_path}")
