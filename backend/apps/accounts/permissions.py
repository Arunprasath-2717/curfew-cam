"""Role-based permissions."""
from rest_framework.permissions import BasePermission
from .models import UserRole


class IsStudent(BasePermission):
    def has_permission(self, request, view):
        print(f"[DEBUG] IsStudent check. User: {request.user.email}, Role: {getattr(request.user, 'role', 'NoRole')}, Auth: {request.user.is_authenticated}")
        return request.user.is_authenticated and request.user.role == UserRole.STUDENT


class IsWarden(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [UserRole.WARDEN, UserRole.ADMIN_WARDEN]


class IsWatchman(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'watchman'


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == UserRole.ADMIN


class IsAdminOrWarden(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [
            UserRole.ADMIN, UserRole.WARDEN, UserRole.ADMIN_WARDEN
        ]


class IsWardenOrWatchman(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [
            UserRole.WARDEN, UserRole.ADMIN_WARDEN, 'watchman'
        ]

class IsAdminWarden(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == UserRole.ADMIN_WARDEN


class IsOwnerOrAdmin(BasePermission):
    """Object-level: only owner or admin can access."""
    def has_object_permission(self, request, view, obj):
        if request.user.role == UserRole.ADMIN:
            return True
        if hasattr(obj, 'user'):
            return obj.user == request.user
        return obj == request.user
