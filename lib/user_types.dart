class UserTypes {
  static const List<String> usertype = [
    'Ward Staff Nurse',
    'Approvers - Ward Incharge',
    'Approvers - Nursing Superintendent',
    'Approvers - RMO (Resident Medical Officer)',
    'Approvers - Medical Superintendent (MS)',
    'Approvers - Dean',
    'Responder - Carpenter',
    'Responder - Plumber',
    'Responder - Housekeeping Supervisor',
    'Responder - Biomedical Engineer',
    'Responder - Civil',
    'Responder - PWD Electrician',
    'Responder - Hospital Electrician',
    'Responder - Laundry',
    'Responder - Manifold',
    'Admin'
  ];
  static const List<String> workertype = [
    'Carpenter',
    'Plumber',
    'Housekeeping Supervisor',
    'Biomedical Engineer',
    'Civil',
    'PWD Electrician',
    'Hospital Electrician',
    'Laundry',
    'Manifold',
  ];
  static const List<String> approvers = [
    'Approvers - Ward Incharge',
    'Approvers - Nursing Superintendent',
    'Approvers - RMO (Resident Medical Officer)',
    'Approvers - Medical Superintendent (MS)',
    'Approvers - Dean',
  ];
  static const List<String> responders = [
    'Responder - Carpenter',
    'Responder - Plumber',
    'Responder - Housekeeping Supervisor',
    'Responder - Biomedical Engineer',
    'Responder - Civil',
    'Responder - PWD Electrician',
    'Responder - Hospital Electrician',
    'Responder - Laundry',
    'Responder - Manifold',
  ];
  static const Map<String, String> userTypeMapping = {
    'Ward Staff Nurse': 'ward_nurse',
    'Approvers - Ward Incharge': 'ward_incharge',
    'Approvers - Nursing Superintendent': 'nursing_superintendent',
    'Approvers - RMO (Resident Medical Officer)': 'rmo',
    'Approvers - Medical Superintendent (MS)': 'medical_superintendent',
    'Approvers - Dean': 'dean',
    'Responder - Carpenter': 'carpenter',
    'Responder - Plumber': 'plumber',
    'Responder - Housekeeping Supervisor': 'housekeeping',
    'Responder - Biomedical Engineer': 'biomedical',
    'Responder - Civil': 'civil',
    'Responder - PWD Electrician': 'pwd_electrician',
    'Responder - Hospital Electrician': 'hospital_electrician',
    'Responder - Laundry': 'laundry',
    'Responder - Manifold': 'manifold',
    'Admin': 'admin',
  };
}
