import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as sgMail from "@sendgrid/mail";

// Initialize Firebase Admin
admin.initializeApp();

// Initialize SendGrid
const sendgridKey = functions.config().sendgrid?. key;
if (sendgridKey) {
  sgMail.setApiKey(sendgridKey);
}

const FROM_EMAIL = functions.config().email?.from || "noreply@educateclassroom.com";

// ==================== EMAIL TEMPLATES ====================

interface EmailTemplate {
  subject: string;
  html: string;
  text: string;
}

function getAnnouncementEmail(
  studentName: string,
  announcementTitle: string,
  announcementContent: string,
  courseName: string,
  instructorName: string
): EmailTemplate {
  return {
    subject: `📢 New Announcement: ${announcementTitle}`,
    html: `
      <! DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .announcement-box { background: white; padding: 20px; border-left: 4px solid #667eea; margin: 20px 0; border-radius: 5px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📢 New Announcement</h1>
          </div>
          <div class="content">
            <p>Hi ${studentName},</p>
            <p>Your instructor <strong>${instructorName}</strong> has posted a new announcement in <strong>${courseName}</strong>:</p>
            <div class="announcement-box">
              <h2>${announcementTitle}</h2>
              <p>${announcementContent}</p>
            </div>
            <p>Log in to view the full announcement and any attachments.</p>
          </div>
          <div class="footer">
            <p>This is an automated email from Educate Classroom.  Please do not reply. </p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `Hi ${studentName},\n\nYour instructor ${instructorName} has posted a new announcement in ${courseName}:\n\n${announcementTitle}\n${announcementContent}\n\nLog in to view the full announcement. `,
  };
}

function getAssignmentSubmittedEmail(
  studentName: string,
  assignmentTitle: string,
  courseName: string,
  attemptNumber: number,
  submittedAt: string
): EmailTemplate {
  return {
    subject: `✅ Assignment Submitted: ${assignmentTitle}`,
    html: `
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1>✅ Assignment Submitted</h1>
          </div>
          <div style="background: #f9f9f9; padding: 30px;">
            <p>Hi ${studentName},</p>
            <p>Your assignment has been submitted successfully!</p>
            <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
              <p><strong>Course:</strong> ${courseName}</p>
              <p><strong>Assignment:</strong> ${assignmentTitle}</p>
              <p><strong>Attempt:</strong> #${attemptNumber}</p>
              <p><strong>Submitted:</strong> ${submittedAt}</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `Hi ${studentName},\n\nYour assignment has been submitted!\n\nCourse: ${courseName}\nAssignment: ${assignmentTitle}\nAttempt: #${attemptNumber}\nSubmitted: ${submittedAt}`,
  };
}

function getAssignmentGradedEmail(
  studentName: string,
  assignmentTitle: string,
  courseName: string,
  score: number,
  totalPoints: number,
  feedback: string | null
): EmailTemplate {
  const percentage = ((score / totalPoints) * 100).toFixed(1);
  return {
    subject: `📊 Assignment Graded: ${assignmentTitle} - ${score}/${totalPoints}`,
    html: `
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1>📊 Assignment Graded</h1>
          </div>
          <div style="background: #f9f9f9; padding: 30px;">
            <p>Hi ${studentName},</p>
            <p>Your assignment for <strong>${courseName}</strong> has been graded!</p>
            <div style="background: white; padding: 30px; text-align: center; border-radius: 10px; margin: 20px 0;">
              <div style="font-size: 48px; font-weight: bold; color: #667eea;">${score}/${totalPoints}</div>
              <div style="font-size: 24px; color: #666;">${percentage}%</div>
              <p style="color: #666;">${assignmentTitle}</p>
            </div>
            ${feedback ? `<div style="background: #fff3cd; padding: 20px; border-left: 4px solid #ffc107; border-radius: 5px;"><h3>💬 Instructor Feedback</h3><p>${feedback}</p></div>` : ""}
          </div>
        </div>
      </body>
      </html>
    `,
    text: `Hi ${studentName},\n\nYour assignment has been graded!\n\nCourse: ${courseName}\nAssignment: ${assignmentTitle}\nScore: ${score}/${totalPoints} (${percentage}%)\n${feedback ? `\nFeedback: ${feedback}` : ""}`,
  };
}

function getQuizSubmittedEmail(
  studentName: string,
  quizTitle: string,
  courseName: string,
  score: number,
  totalQuestions: number,
  submittedAt: string
): EmailTemplate {
  const percentage = ((score / totalQuestions) * 100).toFixed(1);
  return {
    subject: `✅ Quiz Submitted: ${quizTitle} - ${score}/${totalQuestions}`,
    html: `
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1>✅ Quiz Completed</h1>
          </div>
          <div style="background: #f9f9f9; padding: 30px;">
            <p>Hi ${studentName},</p>
            <p>You have successfully completed the quiz for <strong>${courseName}</strong>!</p>
            <div style="background: white; padding: 30px; text-align: center; border-radius: 10px; margin: 20px 0;">
              <div style="font-size: 48px; font-weight: bold; color: #f5576c;">${score}/${totalQuestions}</div>
              <div style="font-size: 24px; color: #666;">${percentage}%</div>
              <p style="color: #666;">${quizTitle}</p>
              <p style="color: #999; font-size: 14px;">Submitted: ${submittedAt}</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `Hi ${studentName},\n\nQuiz completed!\n\nCourse: ${courseName}\nQuiz: ${quizTitle}\nScore: ${score}/${totalQuestions} (${percentage}%)\nSubmitted: ${submittedAt}`,
  };
}

// ==================== HELPER FUNCTIONS ====================

async function sendEmail(
  to: string,
  subject: string,
  html: string,
  text: string
): Promise<void> {
  try {
    if (! sendgridKey) {
      console.log("📧 EMAIL (SendGrid not configured):");
      console.log(`To: ${to}`);
      console.log(`Subject: ${subject}`);
      return;
    }

    await sgMail.send({
      to,
      from: FROM_EMAIL,
      subject,
      html,
      text,
    });

    console.log(`✅ Email sent to ${to}: ${subject}`);
  } catch (error) {
    console. error(`❌ Error sending email to ${to}:`, error);
  }
}

async function getUserData(userId: string): Promise<any> {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  if (!userDoc.exists) throw new Error(`User not found: ${userId}`);
  return {...userDoc.data(), uid: userId};
}

async function getCourseData(courseId: string): Promise<any> {
  const courseDoc = await admin.firestore().collection("courses").doc(courseId).get();
  if (!courseDoc.exists) throw new Error(`Course not found: ${courseId}`);
  return courseDoc.data();
}

// ==================== CLOUD FUNCTIONS ====================

// Trigger email when notification is created
export const onNotificationCreated = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot) => {
    try {
      const notification = snap.data();
      const user = await getUserData(notification.userId);

      if (! user.email) {
        console.log(`⚠️ User ${notification.userId} has no email`);
        return;
      }

      console.log(`📧 Processing notification type: ${notification.type}`);

      switch (notification.type) {
        case "announcement": {
          const announcementDoc = await admin.firestore().collection("announcements").doc(notification. relatedId).get();
          if (announcementDoc.exists) {
            const announcement = announcementDoc.data()!;
            const course = await getCourseData(announcement.courseId);
            const instructor = await getUserData(announcement.createdBy);
            const template = getAnnouncementEmail(
              user.displayName,
              announcement.title,
              announcement.content,
              course.name,
              instructor.displayName
            );
            await sendEmail(user.email, template.subject, template.html, template.text);
          }
          break;
        }

        case "assignmentSubmitted": {
          const assignmentDoc = await admin.firestore().collection("assignments").doc(notification.relatedId).get();
          if (assignmentDoc. exists) {
            const assignment = assignmentDoc.data()!;
            const course = await getCourseData(assignment.courseId);
            const attemptMatch = notification.message.match(/Attempt #(\d+)/);
            const attemptNumber = attemptMatch ? parseInt(attemptMatch[1]) : 1;
            const template = getAssignmentSubmittedEmail(
              user.displayName,
              assignment.title,
              course.name,
              attemptNumber,
              new Date().toLocaleString()
            );
            await sendEmail(user.email, template.subject, template.html, template.text);
          }
          break;
        }

        case "assignmentGraded": {
          const assignmentDoc = await admin.firestore().collection("assignments").doc(notification. relatedId).get();
          if (assignmentDoc.exists) {
            const assignment = assignmentDoc.data()!;
            const course = await getCourseData(assignment.courseId);
            const scoreMatch = notification.message. match(/Score: (\d+)\/(\d+)/);
            const score = scoreMatch ? parseInt(scoreMatch[1]) : 0;
            const totalPoints = scoreMatch ? parseInt(scoreMatch[2]) : 100;
            const template = getAssignmentGradedEmail(
              user. displayName,
              assignment.title,
              course.name,
              score,
              totalPoints,
              null
            );
            await sendEmail(user.email, template.subject, template.html, template.text);
          }
          break;
        }

        case "quizSubmitted":
        case "quizGraded": {
          const quizDoc = await admin.firestore().collection("quizzes").doc(notification. relatedId).get();
          if (quizDoc. exists) {
            const quiz = quizDoc.data()!;
            const course = await getCourseData(quiz.courseId);
            const scoreMatch = notification. message.match(/Score: (\d+)\/(\d+)/);
            const score = scoreMatch ? parseInt(scoreMatch[1]) : 0;
            const total = scoreMatch ? parseInt(scoreMatch[2]) : 10;
            const template = getQuizSubmittedEmail(
              user.displayName,
              quiz.title,
              course.name,
              score,
              total,
              new Date().toLocaleString()
            );
            await sendEmail(user.email, template.subject, template.html, template.text);
          }
          break;
        }

        default:
          console.log(`ℹ️ No email handler for notification type: ${notification.type}`);
      }
    } catch (error) {
      console.error("❌ Error in onNotificationCreated:", error);
    }
  });