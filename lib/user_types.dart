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
  ]; //use this as the mapping types for the topics notification
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

  /// Map from usertype to workertype
  static String? getWorkerTypeFromUserType(String userType) {
    if (userType.startsWith('Responder - ')) {
      return userType.replaceFirst('Responder - ', '');
    }
    return null; // Not a responder
  }

  /// Map from workertype to usertype
  static String? getUserTypeFromWorkerType(String workerType) {
    String responderType = 'Responder - $workerType';
    return responders.contains(responderType) ? responderType : null;
  }

  /// Get topic for notification subscription
  static String? getNotificationTopic(String userType) {
    String? workerType = getWorkerTypeFromUserType(userType);
    return workerType != null
        ? workerType.toLowerCase().replaceAll(' ', '_')
        : null;
  }
}
