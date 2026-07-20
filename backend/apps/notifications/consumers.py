import json
from channels.generic.websocket import AsyncWebsocketConsumer

class NotificationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope.get("user")
        
        # Deny connection if the user is anonymous
        if not self.user or self.user.is_anonymous:
            await self.close(code=4003)  # Forbidden
            return
            
        self.group_name = f"user_{self.user.id}"
        
        # Join group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            # Leave group
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    # Receive message from WebSocket client
    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            action = data.get("action")
            
            # Simple ping-pong mechanism
            if action == "ping":
                await self.send(text_data=json.dumps({"action": "pong"}))
        except Exception:
            pass

    # Receive message from user group
    async def send_notification(self, event):
        payload = event.get("payload")
        
        # Send exact payload to WebSocket client
        if payload:
            await self.send(text_data=json.dumps(payload))
