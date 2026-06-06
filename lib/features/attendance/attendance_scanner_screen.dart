import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subject_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/theme/app_theme.dart';
import 'attendance_summary_screen.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen>
    with TickerProviderStateMixin {
  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPaused = false;
  bool _isProcessing = false;
  String? _lastMessage;
  Color _messageColor = AppTheme.successGreen;
  late AnimationController _pulseController;
  late AnimationController _notifController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _notifAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _notifController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _notifAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _notifController, curve: Curves.easeOut));

    // إنشاء الجلسة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final subject = context.read<SubjectProvider>().activeSubject!;
      await context.read<AttendanceProvider>().startSession(
            subject['id'],
            auth.userCode,
          );
    });
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _notifController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isPaused || _isProcessing) return;
    final String? rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final result = await context.read<AttendanceProvider>().registerAttendance(
          rawValue,
        );

    if (!mounted) return;

    switch (result) {
      case AttendanceScanResult.success:
        await _playSound('success');
        final last = context.read<AttendanceProvider>().lastRegistered;
        _showNotification(
          '✅ ${last?['full_name'] ?? 'تم التسجيل'}',
          AppTheme.successGreen,
        );
        break;
      case AttendanceScanResult.alreadyRegistered:
        await _playSound('warning');
        _showNotification(
          '⚠️ تم تسجيل هذا الطالب مسبقاً',
          AppTheme.warningYellow,
        );
        break;
      case AttendanceScanResult.notFound:
        await _playSound('error');
        _showNotification('❌ الطالب غير موجود في النظام', AppTheme.errorRed);
        break;
      case AttendanceScanResult.wrongMeal:
        await _playSound('error');
        _showNotification('❌ الطالب ينتمي لوجبة أخرى', AppTheme.errorRed);
        break;
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _playSound(String type) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$type.mp3'));
    } catch (_) {
      // الصوت اختياري، لا نوقف التطبيق إذا فشل
    }
  }

  void _showNotification(String message, Color color) {
    setState(() {
      _lastMessage = message;
      _messageColor = color;
    });
    _notifController.forward(from: 0);
  }

  Future<void> _finishSession() async {
    final attendanceProvider = context.read<AttendanceProvider>();

    if (attendanceProvider.totalScanned == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'تنبيه',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          content: Text(
            'لم يتم تسجيل أي طالب. هل تريد المتابعة؟',
            style: TextStyle(color: AppTheme.textGrey),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'نعم',
                style: TextStyle(color: AppTheme.errorRed),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    await attendanceProvider.endSession();
    if (!mounted) return;

    final sessionId = attendanceProvider.currentSessionId!;
    final subject = context.read<SubjectProvider>().activeSubject!;
    final auth = context.read<AuthProvider>();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceSummaryScreen(
          sessionId: sessionId,
          subject: subject,
          instructorName: auth.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subject = context.read<SubjectProvider>().activeSubject!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'تأكيد',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
            content: const Text(
              'سيتم إلغاء الجلسة الحالية. هل تريد الخروج؟',
              style: TextStyle(color: AppTheme.textGrey),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'خروج',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          if (mounted) {
            await context.read<AttendanceProvider>().cancelSession();
            if (mounted) Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // الكاميرا
            MobileScanner(controller: _scannerCtrl, onDetect: _onDetect),
      
            // طبقة التعتيم
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0, 0.25, 0.65, 1],
                ),
              ),
            ),
      
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(subject),
                  const Spacer(),
                  _buildScanFrame(),
                  const Spacer(),
                  _buildBottomPanel(),
                ],
              ),
            ),
      
            // إشعار التسجيل
            if (_lastMessage != null)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: SlideTransition(
                  position: _notifAnimation,
                  child: _buildNotificationBanner(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Map<String, dynamic> subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // زر الرجوع
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppTheme.cardBg,
                title: const Text(
                  'تأكيد',
                  style: TextStyle(color: Colors.white),
                  textDirection: TextDirection.rtl,
                ),
                content: const Text(
                  'سيتم إلغاء الجلسة الحالية. هل تريد الخروج؟',
                  style: TextStyle(color: AppTheme.textGrey),
                  textDirection: TextDirection.rtl,
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await context.read<AttendanceProvider>().cancelSession();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      'خروج',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  ),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${subject['code'] ?? ''} | ${subject['semester'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // إيقاف مؤقت
          GestureDetector(
            onTap: () {
              setState(() => _isPaused = !_isPaused);
              if (_isPaused) {
                _scannerCtrl.stop();
              } else {
                _scannerCtrl.start();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isPaused
                    ? AppTheme.warningYellow.withOpacity(0.3)
                    : Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: _isPaused ? AppTheme.warningYellow : Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // تبديل الكاميرا
          GestureDetector(
            onTap: () => _scannerCtrl.switchCamera(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cameraswitch_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isProcessing
                  ? AppTheme.warningYellow
                  : AppTheme.successGreen,
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              // أركان الإطار
              ...List.generate(4, (i) => _buildCorner(i)),
              if (_isProcessing)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const CircularProgressIndicator(
                      color: AppTheme.warningYellow,
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(int index) {
    final positions = [
      [true, true, false, false],
      [true, false, false, true],
      [false, true, true, false],
      [false, false, true, true],
    ];
    final [top, left, bottom, right] = positions[index];
    return Positioned(
      top: top ? -1 : null,
      left: left ? -1 : null,
      bottom: bottom ? -1 : null,
      right: right ? -1 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: AppTheme.successGreen, width: 4)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: AppTheme.successGreen, width: 4)
                : BorderSide.none,
            bottom: bottom
                ? const BorderSide(color: AppTheme.successGreen, width: 4)
                : BorderSide.none,
            right: right
                ? const BorderSide(color: AppTheme.successGreen, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(8) : Radius.zero,
            topRight: top && right ? const Radius.circular(8) : Radius.zero,
            bottomLeft: bottom && left ? const Radius.circular(8) : Radius.zero,
            bottomRight:
                bottom && right ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final last = provider.lastRegistered;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.people_rounded,
                          color: AppTheme.successGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.totalScanned} طالب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (last != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.successGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      last['full_name'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      last['check_in_time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finishSession,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    'حفظ الحضور وإنهاء الجلسة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isPaused
                    ? '⏸ الكاميرا متوقفة مؤقتاً'
                    : '📷 الكاميرا نشطة — وجّه نحو الباركود',
                style: TextStyle(
                  fontSize: 12,
                  color: _isPaused ? AppTheme.warningYellow : AppTheme.textGrey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _messageColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _messageColor.withOpacity(0.4), blurRadius: 20),
        ],
      ),
      child: Text(
        _lastMessage ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
