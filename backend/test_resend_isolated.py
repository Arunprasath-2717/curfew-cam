import resend

resend.api_key = "re_HfNKR8ik_Bq2aemD96mztYWQaNF1snCws"

try:
    r = resend.Emails.send({
        "from": "onboarding@resend.dev",
        "to": "a62341327@gmail.com",
        "subject": "Test from curfewcam",
        "text": "Hello world"
    })
    print("Success!", r)
except Exception as e:
    print("Error:", e)
