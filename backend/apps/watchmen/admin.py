"""Admin configs for watchmen app."""
from django.contrib import admin
from django import forms
from .models import WatchmanProfile, ShiftLog, GateScan
from apps.accounts.models import User, UserRole

class WatchmanProfileForm(forms.ModelForm):
    first_name = forms.CharField(max_length=150)
    last_name = forms.CharField(max_length=150, required=False)
    phone_number = forms.CharField(max_length=15)
    password = forms.CharField(widget=forms.PasswordInput(), required=False)

    class Meta:
        model = WatchmanProfile
        fields = ('first_name', 'last_name', 'phone_number', 'password', 'employee_id', 'assigned_gate', 'is_on_duty')

    def save(self, commit=True):
        profile = super().save(commit=False)
        phone = self.cleaned_data['phone_number']
        email = f"{phone}@watchman.internal"
        
        if not hasattr(profile, 'user'):
            user = User.objects.create_user(
                email=email,
                password=self.cleaned_data['password'],
                first_name=self.cleaned_data['first_name'],
                last_name=self.cleaned_data['last_name'],
                phone_number=phone,
                role=UserRole.WATCHMAN,
                is_verified=True
            )
            profile.user = user
        else:
            user = profile.user
            user.phone_number = phone
            user.first_name = self.cleaned_data['first_name']
            user.last_name = self.cleaned_data['last_name']
            if self.cleaned_data['password']:
                user.set_password(self.cleaned_data['password'])
            user.save()
        
        if commit:
            profile.save()
        return profile

@admin.register(WatchmanProfile)
class WatchmanProfileAdmin(admin.ModelAdmin):
    form = WatchmanProfileForm
    list_display = ('user', 'employee_id', 'assigned_gate', 'is_on_duty')
    list_filter = ('assigned_gate', 'is_on_duty')
    search_fields = ('employee_id', 'user__first_name', 'user__last_name')


@admin.register(ShiftLog)
class ShiftLogAdmin(admin.ModelAdmin):
    list_display = ('watchman', 'gate', 'shift_start', 'shift_end')
    list_filter = ('gate', 'shift_start')
    date_hierarchy = 'shift_start'


@admin.register(GateScan)
class GateScanAdmin(admin.ModelAdmin):
    list_display = ('qr_pass', 'watchman', 'scan_type', 'gate', 'created_at')
    list_filter = ('scan_type', 'gate', 'created_at')
    search_fields = ('qr_pass__token',)
    date_hierarchy = 'created_at'
