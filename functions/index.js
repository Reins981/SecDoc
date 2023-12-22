/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyNewDocumentPVAll = functions.firestore
    .document('documents_pv-all/{documentId}')
    .onCreate((snapshot, context) => {
        const documentData = snapshot.data();

        const payload = {
            notification: {
                title: 'New Document Available',
                body: `${documentData.document_name} has been added to the library.`,
                // other notification options
            },
        };

        // Send a message to devices subscribed to the "documents" topic
        return admin.messaging().sendToTopic("documents", payload)
            .then((response) => {
                console.log('Successfully sent message:', response);
            })
            .catch((error) => {
                console.log('Error sending message:', error);
            });
    });

exports.notifyNewDocumentPVIBK = functions.firestore
    .document('documents_pv-ibk/{documentId}')
    .onCreate((snapshot, context) => {
        const documentData = snapshot.data();

        const payload = {
            notification: {
                title: 'New Document Available',
                body: `${documentData.document_name} has been added to the library.`,
                // other notification options
            },
        };

        // Send a message to devices subscribed to the "documents" topic
        return admin.messaging().sendToTopic("documents", payload)
            .then((response) => {
                console.log('Successfully sent message:', response);
            })
            .catch((error) => {
                console.log('Error sending message:', error);
            });
    });

exports.notifyNewDocumentPVIBKL = functions.firestore
    .document('documents_pv-ibk-l/{documentId}')
    .onCreate((snapshot, context) => {
        const documentData = snapshot.data();

        const payload = {
            notification: {
                title: 'New Document Available',
                body: `${documentData.document_name} has been added to the library.`,
                // other notification options
            },
        };

        // Send a message to devices subscribed to the "documents" topic
        return admin.messaging().sendToTopic("documents", payload)
            .then((response) => {
                console.log('Successfully sent message:', response);
            })
            .catch((error) => {
                console.log('Error sending message:', error);
            });
    });

exports.notifyNewDocumentPVIM = functions.firestore
    .document('documents_pv-im/{documentId}')
    .onCreate((snapshot, context) => {
        const documentData = snapshot.data();

        const payload = {
            notification: {
                title: 'New Document Available',
                body: `${documentData.document_name} has been added to the library.`,
                // other notification options
            },
        };

        // Send a message to devices subscribed to the "documents" topic
        return admin.messaging().sendToTopic("documents", payload)
            .then((response) => {
                console.log('Successfully sent message:', response);
            })
            .catch((error) => {
                console.log('Error sending message:', error);
            });
    });

exports.notifyNewDocumentPVEXT = functions.firestore
    .document('documents_pv-ext/{documentId}')
    .onCreate((snapshot, context) => {
        const documentData = snapshot.data();

        const payload = {
            notification: {
                title: 'New Document Available',
                body: `${documentData.document_name} has been added to the library.`,
                // other notification options
            },
        };

        // Send a message to devices subscribed to the "documents" topic
        return admin.messaging().sendToTopic("documents", payload)
            .then((response) => {
                console.log('Successfully sent message:', response);
            })
            .catch((error) => {
                console.log('Error sending message:', error);
            });
    });
