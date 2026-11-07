import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/user_api_service.dart';
import 'package:supermarket_manager_system/models/user_detail.dart';
import 'package:supermarket_manager_system/views/widgets/dashboard_header.dart';
import 'package:supermarket_manager_system/views/widgets/change_password_dialog.dart';

class ProfileViewContent extends StatefulWidget {
  const ProfileViewContent({
    super.key,
    required this.fullName,
    required this.userId,
    required this.isCompact,
    required this.currentTimeText,
    required this.onEditProfile,
  });

  final String fullName;
  final int userId;
  final bool isCompact;
  final String currentTimeText;
  final ValueChanged<UserDetail> onEditProfile;

  @override
  State<ProfileViewContent> createState() => _ProfileViewContentState();
}

class _ProfileViewContentState extends State<ProfileViewContent> {
  final _userApiService = UserApiService();
  late Future<UserDetail> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _userApiService.getUserDetail(widget.userId);
  }

  void _reloadProfile() {
    setState(
      () => _profileFuture = _userApiService.getUserDetail(widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2F5),
      child: FutureBuilder<UserDetail>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          final displayName = detail?.fullname.trim().isNotEmpty == true
              ? detail!.fullname
              : widget.fullName;
          return Column(
            children: [
              _ProfileHeader(
                fullName: displayName,
                isCompact: widget.isCompact,
                currentTimeText: widget.currentTimeText,
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || detail == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 520),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8EAED),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Cannot load profile from database',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: _reloadProfile,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: _ProfileInfoCard(
                            detail: detail,
                            onEditProfile: () => widget.onEditProfile(detail),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileEditContent extends StatefulWidget {
  const ProfileEditContent({
    super.key,
    required this.userId,
    required this.initialDetail,
    required this.isCompact,
    required this.currentTimeText,
    required this.onSaved,
    required this.onCancel,
  });

  final int userId;
  final UserDetail? initialDetail;
  final bool isCompact;
  final String currentTimeText;
  final ValueChanged<UserDetail> onSaved;
  final VoidCallback onCancel;

  @override
  State<ProfileEditContent> createState() => _ProfileEditContentState();
}

class _ProfileEditContentState extends State<ProfileEditContent> {
  final _formKey = GlobalKey<FormState>();
  final _userApiService = UserApiService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _idCardController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _dobController;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final detail = widget.initialDetail;
    final fullName = detail?.fullname ?? '';
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: detail?.email ?? '');
    _idCardController = TextEditingController(text: detail?.idCard ?? '');
    _phoneController = TextEditingController(text: detail?.phone ?? '');
    _addressController = TextEditingController(text: detail?.address ?? '');
    _dobController = TextEditingController(text: detail?.dob ?? '');
  }

  Future<void> _pickDob() async {
    DateTime initialDate = DateTime.now();
    if (_dobController.text.trim().isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text.trim());
      } catch (_) {
        initialDate = DateTime.now();
      }
    }

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      _dobController.text = picked.toIso8601String().split('T').first;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final combinedName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();
      final updated = await _userApiService.updateProfile(
        userId: widget.userId,
        fullname: combinedName,
        email: _emailController.text.trim(),
        idCard: _idCardController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        dob: _dobController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      widget.onSaved(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      widget.onCancel();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(
        () => _errorText = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final combinedName = '$firstName $lastName'.trim();
    final displayName = combinedName.isEmpty ? 'Administrator' : combinedName;
    return Container(
      color: const Color(0xFFF0F2F5),
      child: Column(
        children: [
          _ProfileHeader(
            fullName: displayName,
            isCompact: widget.isCompact,
            currentTimeText: widget.currentTimeText,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EAED)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update Personal Information',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              Widget buildRow(Widget first, Widget second) {
                                if (!isWide) {
                                  return Column(
                                    children: [
                                      first,
                                      const SizedBox(height: 20),
                                      second,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: first),
                                    const SizedBox(width: 20),
                                    Expanded(child: second),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildRow(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _ProfileInputLabel(
                                          'First Name *',
                                        ),
                                        const SizedBox(height: 6),
                                        _ProfileEditableField(
                                          controller: _firstNameController,
                                          enabled: !_isSaving,
                                          validator: (value) =>
                                              (value == null ||
                                                  value.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _ProfileInputLabel('Last Name *'),
                                        const SizedBox(height: 6),
                                        _ProfileEditableField(
                                          controller: _lastNameController,
                                          enabled: !_isSaving,
                                          validator: (value) =>
                                              (value == null ||
                                                  value.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  buildRow(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _ProfileInputLabel('Email *'),
                                        const SizedBox(height: 6),
                                        _ProfileEditableField(
                                          controller: _emailController,
                                          enabled: !_isSaving,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            if (!value.contains('@')) {
                                              return 'Email must contain @';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _ProfileInputLabel(
                                          'Phone Number *',
                                        ),
                                        const SizedBox(height: 6),
                                        _ProfileEditableField(
                                          controller: _phoneController,
                                          enabled: !_isSaving,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            final phone = value.trim();
                                            if (!RegExp(
                                              r'^\d+$',
                                            ).hasMatch(phone)) {
                                              return 'Phone must contain only numbers';
                                            }
                                            if (phone.length < 10 ||
                                                phone.length > 15) {
                                              return 'Phone must be 10-15 digits';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  buildRow(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _ProfileInputLabel(
                                          'ID Card Number *',
                                        ),
                                        const SizedBox(height: 6),
                                        _ProfileEditableField(
                                          controller: _idCardController,
                                          enabled: !_isSaving,
                                          hintText: 'Enter ID card number',
                                          validator: (value) =>
                                              (value == null ||
                                                  value.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _ProfileInputLabel(
                                          'Date of Birth',
                                        ),
                                        const SizedBox(height: 6),
                                        _ProfileEditableField(
                                          controller: _dobController,
                                          enabled: !_isSaving,
                                          readOnly: true,
                                          onTap: _pickDob,
                                          hintText: 'yyyy-MM-dd',
                                          suffixIcon:
                                              Icons.calendar_today_outlined,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return null;
                                            }
                                            final pattern = RegExp(
                                              r'^\d{4}-\d{2}-\d{2}$',
                                            );
                                            if (!pattern.hasMatch(
                                              value.trim(),
                                            )) {
                                              return 'Format: yyyy-MM-dd';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const _ProfileInputLabel('Address'),
                                  const SizedBox(height: 6),
                                  _ProfileEditableField(
                                    controller: _addressController,
                                    enabled: !_isSaving,
                                    hintText: 'Enter your address',
                                    maxLines: 4,
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _errorText!,
                              style: const TextStyle(color: Color(0xFFB91C1C)),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C5DAB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Update',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextButton(
                                  onPressed: _isSaving ? null : widget.onCancel,
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B7280),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.isCompact,
    required this.currentTimeText,
  });

  final String fullName;
  final bool isCompact;
  final String currentTimeText;

  @override
  Widget build(BuildContext context) {
    return DashboardHeader(
      title: 'My Profile',
      fullName: fullName,
      roleLabel: 'Manager',
      currentTimeText: currentTimeText,
      isCompact: isCompact,
      timeChipColor: const Color(0xFF4ECDC4),
      avatarColor: const Color(0xFF1E293B),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.detail, required this.onEditProfile});

  final UserDetail detail;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    detail.fullname.isNotEmpty
                        ? detail.fullname[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Admin ID - ${detail.id}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Text(
                  detail.fullname.isEmpty ? 'Administrator' : detail.fullname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    detail.status.isEmpty ? 'Unknown' : detail.status,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _ProfileBullet(
            text: detail.phone.isEmpty
                ? 'Phone: N/A'
                : 'Phone: ${detail.phone}',
          ),
          _ProfileBullet(
            text: detail.email.isEmpty
                ? 'Email: N/A'
                : 'Email: ${detail.email}',
          ),
          _ProfileBullet(
            text: detail.idCard.isEmpty
                ? 'ID Card Number: N/A'
                : 'ID Card Number: ${detail.idCard}',
          ),
          _ProfileBullet(
            text: detail.dob.isEmpty ? 'DOB: N/A' : 'DOB: ${detail.dob}',
          ),
          _ProfileBullet(
            text: detail.address.isEmpty
                ? 'Address: N/A'
                : 'Address: ${detail.address}',
          ),
          _ProfileBullet(
            text: detail.role.isEmpty ? 'Role: N/A' : 'Role: ${detail.role}',
          ),
          const SizedBox(height: 20),
          const Text(
            'Authentication Details',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Divider(color: Color(0xFFE2E8F0)),
          _AuthDetailRow(label: 'User Name :', value: detail.username),
          _AuthDetailRow(label: 'Last Login:', value: detail.lastLogin),
          const _AuthDetailRow(label: 'Registered:', value: '—'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEditProfile,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Update Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) => InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => ChangePasswordDialog(userId: detail.id),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7280),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Change Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileBullet extends StatelessWidget {
  const _ProfileBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _AuthDetailRow extends StatelessWidget {
  const _AuthDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInputLabel extends StatelessWidget {
  const _ProfileInputLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF475569),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfileEditableField extends StatelessWidget {
  const _ProfileEditableField({
    required this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.maxLines = 1,
    this.hintText,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final int maxLines;
  final String? hintText;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 20, color: const Color(0xFF64748B))
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD5DCE5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD5DCE5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF667EEA)),
        ),
      ),
    );
  }
}
