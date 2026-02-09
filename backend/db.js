require('dotenv').config();
const mongoose = require('mongoose');
DB_URL = process.env.DB_URL;


mongoose.connect(DB_URL).then(()=>{console.log("Database Connected")});


const userSchema = new mongoose.Schema({
    fullName: {
    type: String,
    required: true,
    minlength: 2,
    maxlength: 50,
  },
    email: { type: String, required: true, unique: true},
    contactNumber: { type: String, required: true,unique: true},
    password: { type: String, required: true },
    resetToken: { type: String, default: null },              
    resetTokenExpiry: { type: Date, default: null },
    role: {
    type: String,
    default: 'user',
  },
  });

  const complaintSchema = new mongoose.Schema({
    complaintType: {
      type: String,
      required: true,
      enum: ['Water Supply', 'Road Maintenance', 'Power Outage', 'Waste Management'],
      trim: true
    },
    description: {
      type: String,
      required: true,
      trim: true,
      maxlength: 1000
    },
    shortDescription: {
      type : String,
      required: true,
    }, 
    image: {
      type: String, // Store the path to the uploaded image
      required: false
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true
      },
      address: {
        type: String,
        required: false
      }
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    status: {
      type: String,
      enum: ['Pending', 'In Progress', 'Resolved', 'Rejected', 'Dispute'],
      default: 'Pending'
    },
    createdAt: {
      type: Date,
      default: Date.now
    },
    updatedAt: {
      type: Date,
      default: Date.now
    }
  });

const RefreshTokenSchema = new mongoose.Schema({
  token: { type: String, required: true },
  userId: { 
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',                         
    required: true 
  },
});
 

const notificationSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  complaintId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Complaint',
    required: true
  },
  message: {
    type: String,
    required: true
  },
  read: {
    type: Boolean,
    default: false
  },
  actionRequired: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  resolvedAt: {
    type: Date
  },
  userAction: {
    type: String,
    enum: ['confirmed', 'disputed'], 
    default: null
  },
  actionTakenAt: { 
    type: Date
  }
});

const verificationRequestSchema = new mongoose.Schema({
email: { type: String, unique: true, sparse: true },
phone: { type: String, unique: true, sparse: true },
  emailOtp: String,
  emailOtpExpiry: Date,
  phoneOtp: String,
  phoneOtpExpiry: Date,
  emailVerified: { type: Boolean, default: false },
  phoneVerified: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  newEmail: String
});

const AdminSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
    minlength: 2,
    maxlength: 50,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
  },
  department: {
    type: String,
    enum: ['Water Supply', 'Road Maintenance'],
    required: true,
  },
  password: {
    type: String,
    required: true,
  },
  contactNumber: {
    type: String,
    match: [/^\d{10}$/, 'Must be 10 digits'],
  },
  role: {
    type: String,
    default: 'admin',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  resetToken: { type: String, default: null },              
  resetTokenExpiry: { type: Date, default: null },
});

complaintSchema.index({ location: '2dsphere' });
  
const adminModel = mongoose.model('Admin', AdminSchema);
const Complaint = mongoose.model('Complaint', complaintSchema);
const usermd = mongoose.model('User', userSchema);
const RefreshTokenModel = mongoose.model('RefreshToken', RefreshTokenSchema);
const Notification = mongoose.model('Notification', notificationSchema);
const VerificationRequest = mongoose.model('VerificationRequest', verificationRequestSchema);

module.exports = { usermd, Complaint,  RefreshTokenModel, Notification,VerificationRequest, adminModel };