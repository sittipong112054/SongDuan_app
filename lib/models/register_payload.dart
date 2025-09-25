enum RegisterRole { member, rider }

class RegisterPayload {
  RegisterPayload({
    required this.username,
    required this.password,
    required this.role,
  });

  final String username;
  final String password;
  final RegisterRole role;

  String get dbRole => role == RegisterRole.rider ? 'RIDER' : 'MEMBER';
}
