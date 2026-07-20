from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import AuthenticationFailed
from django.utils.translation import gettext_lazy as _

class SingleSessionJWTAuthentication(JWTAuthentication):
    def authenticate(self, request):
        result = super().authenticate(request)
        if result is None:
            return None
            
        user, token = result
        
        session_id = token.payload.get('session_id')
        
        if user.current_session_id and str(user.current_session_id) != session_id:
            raise AuthenticationFailed(
                _('Session expired or invalidated by a new login.'),
                code='session_invalidated',
            )
            
        return user, token
