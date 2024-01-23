
//function to send subscription ending in 10 days Notification

// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// const twilio = require('twilio');

// admin.initializeApp();
// const db = admin.firestore();

// const accountSid = 'AC1602a40a00fcda0b389cb70d849ff31b';
// const authToken = '01c487df2827d966c1352cfda142e6b2';
// const twilioPhoneNumber = '+14155238886'; // Replace with your Twilio phone number
// const twilioClient = twilio(accountSid, authToken);

// exports.sendWhatsAppMessagesfor10Days = functions.pubsub.schedule('every 1 minutes').timeZone('Asia/Kolkata').onRun(async (context) => {
//   try {
//     const subscriptions = await db.collection('Subscriptions').where('active', '==', true).get();

//     subscriptions.forEach(async (subscription) => {
//       const endDate = subscription.data().enddate.toDate();
//       const currentDate = new Date();
//       const daysLeft = Math.floor((endDate - currentDate) / (1000 * 60 * 60 * 24)) + 1;
//       const phoneNumber = subscription.data().contact;
//       const toPhoneNumber = `whatsapp:91${phoneNumber}`;

//       console.log(`days left for ${subscription.data().name} is ${daysLeft}`)

//       if (daysLeft === 10) {
//         const name = subscription.data().name;
//         const packageName = subscription.data().package; // Add the field representing the phone number

//         const messageBody = `Hey! *${name}* Your package of *${packageName}* is expiring in *${daysLeft}* Days. - KR Fitness.`;

//         // Use Twilio to send WhatsApp message
//         twilioClient.messages
//           .create({
//             from: `whatsapp:${twilioPhoneNumber}`,
//             body: messageBody,
//             to: toPhoneNumber,
//           })
//           .then((message) => {
//             console.log('WhatsApp message sent successfully:', message.sid);
//           })
//           .catch((error) => {
//             console.error('Error sending WhatsApp message:', error);
//           });
//       }
//     });

//     return null;
//   } catch (error) {
//     console.error('Error sending WhatsApp messages:', error);
//     return null;
//   }
// });


// function for ending today customers


// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// const twilio = require('twilio');

// admin.initializeApp();
// const db = admin.firestore();

// const accountSid = 'AC1602a40a00fcda0b389cb70d849ff31b';
// const authToken = '01c487df2827d966c1352cfda142e6b2';
// const twilioPhoneNumber = '+14155238886'; // Replace with your Twilio phone number
// const twilioClient = twilio(accountSid, authToken);

// exports.sendWhatsAppMessagesEndingToday = functions.pubsub.schedule('every 1 minutes').timeZone('Asia/Kolkata').onRun(async (context) => {
//   try {
//     const subscriptions = await db.collection('Subscriptions').where('active', '==', true).get();

//     subscriptions.forEach(async (subscription) => {
//       const endDate = subscription.data().enddate.toDate();
//       const currentDate = new Date();
//       const daysLeft = Math.floor((endDate - currentDate) / (1000 * 60 * 60 * 24)) + 1;
//       const phoneNumber = subscription.data().contact;
//       const toPhoneNumber = `whatsapp:91${phoneNumber}`;

//       console.log(`days left for ${subscription.data().name} is ${daysLeft}`)

//       if (daysLeft === 0) {
//         const name = subscription.data().name;
//         const packageName = subscription.data().package; // Add the field representing the phone number

//         const messageBody = `Hey! *${name}* Your package of *${packageName}* is ending today. Please Renew Asap - KR Fitness.`;

//         // Use Twilio to send WhatsApp message
//         twilioClient.messages
//           .create({
//             from: `whatsapp:${twilioPhoneNumber}`,
//             body: messageBody,
//             to: toPhoneNumber,
//           })
//           .then((message) => {
//             console.log('WhatsApp message sent successfully:', message.sid);
//           })
//           .catch((error) => {
//             console.error('Error sending WhatsApp message:', error);
//           });
//       }
//     });

//     return null;
//   } catch (error) {
//     console.error('Error sending WhatsApp messages:', error);
//     return null;
//   }
// });


// function for ending overdue customers


// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// const twilio = require('twilio');

// admin.initializeApp();
// const db = admin.firestore();

// const accountSid = 'AC1602a40a00fcda0b389cb70d849ff31b';
// const authToken = '01c487df2827d966c1352cfda142e6b2';
// const twilioPhoneNumber = '+14155238886'; // Replace with your Twilio phone number
// const twilioClient = twilio(accountSid, authToken);

// exports.sendWhatsAppMessagesEndingToday = functions.pubsub.schedule('every 1 minutes').timeZone('Asia/Kolkata').onRun(async (context) => {
//   try {
//     const subscriptions = await db.collection('Subscriptions').where('active', '==', true).get();

//     subscriptions.forEach(async (subscription) => {
//       const endDate = subscription.data().enddate.toDate();
//       const currentDate = new Date();
//       const daysLeft = Math.floor((endDate - currentDate) / (1000 * 60 * 60 * 24)) + 1;
//       const phoneNumber = subscription.data().contact;
//       const toPhoneNumber = `whatsapp:91${phoneNumber}`;
//       // Options for date formatting
//       const options = { day: 'numeric', month: 'short', year: 'numeric' };

//       // Format the date
//       const formattedDate = endDate.toLocaleDateString('en-US', options);

//       console.log(`days left for ${subscription.data().name} is ${daysLeft}`)

//       if (daysLeft < 0) {
//         const name = subscription.data().name;
//         const packageName = subscription.data().package; // Add the field representing the phone number

//         const messageBody = `Hey! *${name}* Your package of *${packageName}* has ended on *${formattedDate}*. Please Renew Asap to avoid overdue charge - KR Fitness.`;

//         // Use Twilio to send WhatsApp message
//         twilioClient.messages
//           .create({
//             from: `whatsapp:${twilioPhoneNumber}`,
//             body: messageBody,
//             to: toPhoneNumber,
//           })
//           .then((message) => {
//             console.log('WhatsApp message sent successfully:', message.sid);
//           })
//           .catch((error) => {
//             console.error('Error sending WhatsApp message:', error);
//           });
//       }
//     });

//     return null;
//   } catch (error) {
//     console.error('Error sending WhatsApp messages:', error);
//     return null;
//   }
// });


// function for pending payments

// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// const twilio = require('twilio');

// admin.initializeApp();
// const db = admin.firestore();

// const accountSid = 'AC1602a40a00fcda0b389cb70d849ff31b';
// const authToken = '01c487df2827d966c1352cfda142e6b2';
// const twilioPhoneNumber = '+14155238886'; // Replace with your Twilio phone number
// const twilioClient = twilio(accountSid, authToken);

// exports.sendPendingPaymentMessages = functions.pubsub.schedule('every 1 minutes').timeZone('Asia/Kolkata').onRun(async (context) => {
//   try {
//     const subscriptionsWithPendingPayments = await db.collection('Subscriptions').where('paymentduedate', '!=', null).get();

//     subscriptionsWithPendingPayments.forEach(async (subscription) => {
//       const paymentDueDate = subscription.data().paymentduedate.toDate();
//       const currentDate = new Date();
//       const daysLeftForPayment = Math.floor((paymentDueDate - currentDate) / (1000 * 60 * 60 * 24)) + 1;

//       if (daysLeftForPayment === 2) {
//         const name = subscription.data().name;
//         const package = subscription.data().package;
//         const pendingAmount = subscription.data().pendingamount;
//         const phoneNumber = subscription.data().contact;
//         const toPhoneNumber = `whatsapp:91${phoneNumber}`;
//         const messageBody = `Hey *${name}*, your payment of *${pendingAmount}₹* for package *${package}* is due in *${daysLeftForPayment} Days*. Please pay it asap.`;

//         // Use Twilio to send WhatsApp message
//         twilioClient.messages
//           .create({
//             from: `whatsapp:${twilioPhoneNumber}`,
//             body: messageBody,
//             to: toPhoneNumber,
//           })
//           .then((message) => {
//             console.log('WhatsApp message sent successfully:', message.sid);
//           })
//           .catch((error) => {
//             console.error('Error sending WhatsApp message:', error);
//           });
//       }
//     });

//     return null;
//   } catch (error) {
//     console.error('Error sending pending payment messages:', error);
//     return null;
//   }
// });


//notification function on sub ending customers

// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// admin.initializeApp();

// exports.dailyNotificationForEndingSubscriptions = functions.pubsub.schedule('every 1 minutes').timeZone('Asia/Kolkata').onRun(async (context) => {
//     const todayTimestamp = admin.firestore.Timestamp.now();
//     const today = todayTimestamp.toDate();


//   const subscriptionsSnapshot = await admin.firestore().collection('Subscriptions')
//     .where('active', '==', true)
//     .get();

//   let counter = 0; // Counter for subscriptions ending today or with pending payments

//   subscriptionsSnapshot.forEach((doc) => {
//     const subscription = doc.data();

//     const adjustedEndDate = new Date(subscription.enddate.toDate());
//     adjustedEndDate.setHours(adjustedEndDate.getHours() + 5);
//     adjustedEndDate.setMinutes(adjustedEndDate.getMinutes() + 30);

    
//     // Check if subscription is ending today
//     if (adjustedEndDate.toLocaleDateString('en-IN') === today.toLocaleDateString('en-IN')) {
//       counter++;
//     }
//   });


//   if (counter > 0) {
//         const userRolesSnapshot = await admin.firestore().collection('UserRoles')
//             .where('notifications', '==', true)
//             .get();

//         userRolesSnapshot.forEach((userRoleDoc) => {
//             const userRole = userRoleDoc.data();
//             const fcmToken = userRole.FCMtoken; // Replace with your actual field name for FCM token
//             const name = userRole.name;

//             const message = {
//                 notification: {
//                     title: 'Members Subscription Reminder',
//                     body: `Hey ${name}, there are ${counter} Members to be Addressed today. Please take action.`,
//                 },
//                 token: fcmToken, // Use the fetched FCM token
//             };

//             admin.messaging().send(message)
//                 .then((response) => {
//                     console.log('Notification sent successfully:', response);
//                 })
//                 .catch((error) => {
//                     console.error('Error sending notification:', error);
//                 });
//         });
//   }

//   return null;
// });



//function for overudue customers

// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// admin.initializeApp();

// exports.dailyNotificationForOverdueSubscriptions = functions.pubsub.schedule('every 1 minutes').timeZone('Asia/Kolkata').onRun(async (context) => {
//     const today = new Date();
//     today.setHours(0, 0, 0, 0);

//     const subscriptionsSnapshot = await admin.firestore().collection('Subscriptions')
//         .where('active', '==', true)
//         .get();

//     let counter = 0; // Counter for subscriptions ending today or with pending payments

//     subscriptionsSnapshot.forEach((doc) => {
//         const subscription = doc.data();

//         const endDate = new Date(subscription.enddate.toDate());
//         endDate.setHours(endDate.getHours() + 5); // Add 5 hours
//         endDate.setMinutes(endDate.getMinutes() + 30);



//         // Check if subscription is ending today
//         if (endDate < today) {
//             counter++;
//         }
//     });


//     if (counter > 0) {
//         const userRolesSnapshot = await admin.firestore().collection('UserRoles')
//             .where('notifications', '==', true)
//             .get();

//         userRolesSnapshot.forEach((userRoleDoc) => {
//             const userRole = userRoleDoc.data();
//             const fcmToken = userRole.FCMtoken; // Replace with your actual field name for FCM token
//             const name = userRole.name;

//             const message = {
//                 notification: {
//                     title: 'Overdue Members Reminder',
//                     body: `Hey ${name}, there are ${counter} client subscriptions Which are Overdue. Please take action.`,
//                 },
//                 token: fcmToken, // Use the fetched FCM token
//             };

//             admin.messaging().send(message)
//                 .then((response) => {
//                     console.log('Notification sent successfully:', response);
//                 })
//                 .catch((error) => {
//                     console.error('Error sending notification:', error);
//                 });
//         });
//     }

//     return null;
// });
  







