const twilio = require('twilio');
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

exports.sendEmailOTP = async (req, res) => {
    const email = (req.body.email || req.body.recipient || "").trim();
    if (!email) return res.status(400).json({ success: false, message: "Email required" });
    try {
        await client.verify.v2.services(serviceSid).verifications.create({ to: email, channel: 'email' });
        res.status(200).json({ success: true, message: "OTP sent!" });
    } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};

exports.verifyEmailOTP = async (req, res) => {
    const email = (req.body.email || req.body.recipient || "").trim();
    const { otp } = req.body;
    try {
        const check = await client.verify.v2.services(serviceSid).verificationChecks.create({ to: email, code: otp });
        res.status(200).json({
            success: check.status === 'approved',
            verified: check.status === 'approved'
        });
    } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};

exports.sendPhoneOTP = async (req, res) => {
    let phone = (req.body.phoneNumber || req.body.phone || "").trim();
    if (!phone) return res.status(400).json({ success: false, message: "Phone required" });
    const formatted = phone.startsWith('+') ? phone : `+91${phone}`;
    try {
        await client.verify.v2.services(serviceSid).verifications.create({ to: formatted, channel: 'sms' });
        res.status(200).json({ success: true, message: "OTP sent!" });
    } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};

exports.verifyPhoneOTP = async (req, res) => {
    let phone = (req.body.phoneNumber || req.body.phone || "").trim();
    const { otp } = req.body;
    const formatted = phone.startsWith('+') ? phone : `+91${phone}`;
    try {
        const check = await client.verify.v2.services(serviceSid).verificationChecks.create({ to: formatted, code: otp });
        res.status(200).json({
            success: check.status === 'approved',
            verified: check.status === 'approved'
        });
    } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};