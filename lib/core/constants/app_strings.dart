class AppStrings {
  static const appName = 'Expense Radar';
  static const unknownError = 'unknown error';

  // Dashboard
  static const dashboardTitle = 'Expense Radar';
  static const dashboardRefreshTooltip = 'Refresh';
  static const dashboardVoiceTooltip = 'Voice';
  static const dashboardStatsError = 'Could not load latest dashboard stats.';
  static const dashboardLoadingSubtitle =
      'Updating today and monthly totals...';
  static const dashboardSubtitle = 'Smarter tracking for calmer spending.';
  static const dashboardQuickActions = 'Quick actions';
  static const dashboardTodayAtAGlance = 'Today at a glance';
  static const dashboardInsightTitleToday = 'Today';
  static const dashboardInsightTitleMonth = 'This month';
  static const dashboardSpendTrendTitle = 'Spending trend';
  static const dashboardCategoriesTitle = 'Categories';

  // Scan landing
  static const scanTitle = 'Scan receipt';
  static const scanSubtitle =
      'Use camera, import from gallery, or add expense manually when no bill is available.';
  static const scanReadyTitle = 'Ready when you are';
  static const scanReadySubtitle =
      'Take a clear photo for better OCR amount detection.';
  static const scanOpenCamera = 'Open camera';
  static const scanImportGallery = 'Import from gallery';
  static const scanNoBillManual = 'No bill? Enter manually';
  static const scanNoImageSelected = 'No image selected';
  static const scanImportFailed = 'Gallery import failed';
  static const scanLoading = 'Loading...';

  // OCR fallback
  static const ocrNoImageFallback =
      'No image found. Please enter expense details manually.';
  static const ocrUnavailablePhotoFallback =
      'Photo is unavailable. Try capturing again or fill the form manually.';
  static const ocrLowConfidenceFallback =
      'Could not read text clearly. Please review and complete details manually.';
  static const ocrFailedFallback =
      'OCR failed. Please enter expense details manually.';

  // Voice fallback
  static const voiceAlreadyRunning = 'Voice capture is already running.';
  static const voicePermissionUnavailable =
      'Microphone permission is unavailable. You can type your command instead.';
  static const voiceInitUnavailable =
      'Voice service could not initialize. You can type your command instead.';
  static const voiceRecognitionUnavailable =
      'Voice recognition is unavailable. Type your command instead.';
  static const voiceCaptureFailed = 'Voice capture failed.';
  static const voiceCaptureFailedFallback =
      'Voice capture failed. Type your command manually.';
  static const voiceSpeakEmpty = 'No response text to speak.';
  static const voiceSpeakFailed =
      'Voice playback failed. Showing text response instead.';

  // Encryption
  static const encryptionPayloadPrefix = 'enc:v1:';
  static const encryptionStorageKey = 'expense_data_encryption_key_v1';
}
