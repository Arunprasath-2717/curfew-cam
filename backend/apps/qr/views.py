"""QR views."""
from rest_framework import permissions
from rest_framework.views import APIView

from apps.common.responses import success_response, error_response
from apps.accounts.permissions import IsStudent, IsWatchman, IsAdminOrWarden
from apps.outpass.models import Outpass
from .models import QRPass
from .serializers import QRPassSerializer, QRValidateSerializer
from .services import generate_qr_for_outpass, regenerate_qr_for_outpass, validate_qr_token


class QRGenerateView(APIView):
    """Generate QR for an approved outpass."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request, outpass_id):
        try:
            outpass = Outpass.objects.get(pk=outpass_id)
        except Outpass.DoesNotExist:
            return error_response('Outpass not found', status_code=404)

        if not hasattr(request.user, 'student_profile') or outpass.student != request.user.student_profile:
            return error_response('Permission denied', status_code=403)

        if outpass.status != Outpass.Status.APPROVED:
            return error_response('Outpass must be approved to generate QR')

        # Check if QR already exists
        if hasattr(outpass, 'qr_pass'):
            return success_response(
                data=QRPassSerializer(outpass.qr_pass).data,
                message='QR already exists for this outpass',
            )

        qr_pass = generate_qr_for_outpass(outpass)
        return success_response(
            data=QRPassSerializer(qr_pass).data,
            message='QR code generated',
        )


class QRValidateView(APIView):
    """Validate a QR token."""
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        serializer = QRValidateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        valid, result = validate_qr_token(serializer.validated_data['token'])
        if not valid:
            return error_response(result)

        return success_response(
            data=QRPassSerializer(result).data,
            message='QR is valid',
        )


class QRDetailView(APIView):
    """Get QR details for an outpass."""
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, outpass_id):
        try:
            qr_pass = QRPass.objects.select_related('outpass__student__user').get(outpass_id=outpass_id)
        except QRPass.DoesNotExist:
            return error_response('QR not found', status_code=404)

        user = request.user
        if user.role == 'student':
            if not hasattr(user, 'student_profile') or qr_pass.outpass.student != user.student_profile:
                return error_response('Permission denied', status_code=403)
        elif user.role not in ('warden', 'admin_warden', 'admin', 'watchman'):
             return error_response('Permission denied', status_code=403)

        return success_response(data=QRPassSerializer(qr_pass).data)


class QRRegenerateView(APIView):
    """Regenerate QR for an approved outpass."""
    permission_classes = (permissions.IsAuthenticated, IsStudent)

    def post(self, request, outpass_id):
        try:
            outpass = Outpass.objects.get(pk=outpass_id)
        except Outpass.DoesNotExist:
            return error_response('Outpass not found', status_code=404)

        if not hasattr(request.user, 'student_profile') or outpass.student != request.user.student_profile:
            return error_response('Permission denied', status_code=403)

        if outpass.status not in (Outpass.Status.APPROVED, Outpass.Status.ACTIVE):
            return error_response('Outpass must be approved to generate QR')

        qr_pass = regenerate_qr_for_outpass(outpass)
        return success_response(
            data=QRPassSerializer(qr_pass).data,
            message='QR code regenerated',
        )
