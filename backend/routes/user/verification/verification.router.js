const express = require('express');
const router = express.Router();
const controller = require('./verification.controller');

// Email Endpoints
router.post('/email-otp', controller.sendEmailOTP);
router.post('/verify-email', controller.verifyEmailOTP);

// Phone Endpoints
router.post('/phone-otp', controller.sendPhoneOTP);
router.post('/verify-phone', controller.verifyPhoneOTP);

module.exports = router;