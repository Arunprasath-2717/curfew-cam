import logging
from celery import shared_task
from django.db import transaction
from django.utils import timezone
from .models import StudentProfile

logger = logging.getLogger(__name__)

@shared_task
def run_yearly_promotion():
    """
    Increment year for active students in year 1,2,3.
    Archive students in year 4.
    """
    try:
        with transaction.atomic():
            # Archive 4th year students
            fourth_years = StudentProfile.objects.filter(year=4, user__is_active=True).select_related('user')
            archived_count = 0
            for student in fourth_years:
                student.user.is_active = False
                student.user.save()
                archived_count += 1
            
            # Promote 1st, 2nd, 3rd year students
            promoted_counts = {1: 0, 2: 0, 3: 0}
            
            # We must promote from 3->4, then 2->3, then 1->2 to avoid double promotions
            for yr in [3, 2, 1]:
                students = StudentProfile.objects.filter(year=yr, user__is_active=True)
                count = students.update(year=yr + 1)
                promoted_counts[yr] = count

            summary = {
                'promoted_to_year_2': promoted_counts[1],
                'promoted_to_year_3': promoted_counts[2],
                'promoted_to_year_4': promoted_counts[3],
                'archived_graduates': archived_count,
            }
            
            logger.info(f"Yearly promotion complete. {summary}")
            return summary
            
    except Exception as e:
        logger.exception("Yearly promotion failed")
        raise e
