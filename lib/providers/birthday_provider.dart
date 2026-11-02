import 'package:flutter/material.dart';
import '../models/birthday/birthday_event.dart';
import '../models/birthday/birthday_expense.dart';
import '../models/birthday/birthday_task.dart';
import '../models/birthday/birthday_guest.dart';
import '../models/birthday/birthday_gift.dart';
import '../models/birthday/birthday_timeline_item.dart';
import '../models/birthday/birthday_memory.dart';
import '../models/birthday/birthday_service_models.dart';
import '../models/birthday/birthday_booking_model.dart';
import '../models/birthday/birthday_payment_model.dart';
import '../models/birthday/birthday_shared_photo_model.dart';
import '../screens/birthday/services/birthday_service.dart';
import '../services/supabase_birthday_service.dart';

class BirthdayProvider extends ChangeNotifier {
  List<BirthdayEvent> _events = [];
  BirthdayEvent? _activeEvent;
  List<BirthdayExpense> _expenses = [];
  List<BirthdayTask> _tasks = [];
  List<BirthdayGuest> _guests = [];
  List<BirthdayGift> _gifts = [];
  List<BirthdayTimelineItem> _timeline = [];
  List<BirthdayMemory> _memories = [];
  bool _isLoading = false;

  // ===== NEW: SERVICE SELECTION, BOOKING & GALLERY STATE =====
  List<BirthdayServicePackage> _packages = [];
  final List<BirthdayServiceCartItem> _serviceCart = [];
  List<BirthdayBooking> _userBookings = [];
  List<BirthdaySharedPhoto> _sharedPhotos = [];
  DateTime? _selectedBookingDate;
  BirthdayTimeSlot? _selectedBookingSlot;
  String? _activeReservationToken;

  // Getters
  List<BirthdayEvent> get events => _events;
  BirthdayEvent? get activeEvent => _activeEvent;
  List<BirthdayExpense> get expenses => _expenses;
  List<BirthdayTask> get tasks => _tasks;
  List<BirthdayGuest> get guests => _guests;
  List<BirthdayGift> get gifts => _gifts;
  List<BirthdayTimelineItem> get timeline => _timeline;
  List<BirthdayMemory> get memories => _memories;
  bool get isLoading => _isLoading;

  // Service & Booking Getters
  List<BirthdayServicePackage> get packages => _packages;
  List<BirthdayServiceCartItem> get serviceCart => List.unmodifiable(_serviceCart);
  List<BirthdayBooking> get userBookings => _userBookings;
  List<BirthdaySharedPhoto> get sharedPhotos => _sharedPhotos;
  DateTime? get selectedBookingDate => _selectedBookingDate;
  BirthdayTimeSlot? get selectedBookingSlot => _selectedBookingSlot;
  String? get activeReservationToken => _activeReservationToken;

  int get cartItemCount => _serviceCart.length;
  double get cartSubtotal => _serviceCart.fold(0.0, (sum, item) => sum + item.totalCost);
  double get cartServiceFee => cartSubtotal > 0 ? (cartSubtotal * 0.03).roundToDouble() : 0.0;
  double get cartTotal => cartSubtotal + cartServiceFee;

  // ===== Derived Stats =====
  List<BirthdayEvent> get upcomingEvents => _events.where((e) => e.daysRemaining > 0).toList()
    ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  int get totalTasksCompleted => _tasks.where((t) => t.isCompleted).length;
  int get totalTasksPending => _tasks.where((t) => !t.isCompleted).length;
  double get taskCompletionPercent => _tasks.isEmpty ? 0 : (totalTasksCompleted / _tasks.length * 100);

  double get totalEstimatedBudget => _expenses.fold(0, (s, e) => s + e.estimatedCost);
  double get totalActualSpending => _expenses.fold(0, (s, e) => s + e.actualCost);
  double get remainingBudget => (_activeEvent?.totalBudget ?? 0) - totalActualSpending;
  double get budgetUtilization => (_activeEvent?.totalBudget ?? 0) == 0
      ? 0
      : (totalActualSpending / _activeEvent!.totalBudget * 100).clamp(0, 999);

  int get totalInvited => _guests.length;
  int get confirmedGuests => _guests.where((g) => g.rsvpStatus == 'accepted').length;
  int get pendingGuests => _guests.where((g) => g.rsvpStatus == 'pending').length;
  int get declinedGuests => _guests.where((g) => g.rsvpStatus == 'declined').length;

  double get eventReadiness {
    if (_activeEvent == null) return 0;
    double score = 0;
    int factors = 0;
    // Task completion
    if (_tasks.isNotEmpty) {
      score += taskCompletionPercent;
      factors++;
    }
    // Has guests
    if (_guests.isNotEmpty) {
      score += (_guests.where((g) => g.rsvpStatus == 'accepted').length / _guests.length * 100);
      factors++;
    }
    // Has budget set
    if (_expenses.isNotEmpty) {
      score += 100;
      factors++;
    }
    // Theme selected
    if (_activeEvent!.theme.isNotEmpty && _activeEvent!.theme != 'Minimal Classy') {
      score += 100;
      factors++;
    }
    return factors == 0 ? 0 : score / factors;
  }

  // ===== INITIALIZATION =====
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await BirthdayService.loadEvents();
      if (_events.isNotEmpty && _activeEvent == null) {
        _activeEvent = _events.first;
      }
      if (_activeEvent != null) {
        await loadEventData(_activeEvent!.id);
      }
      // Load packages & bookings from Supabase service
      _packages = await SupabaseBirthdayService.fetchAllPackages();
      _userBookings = await SupabaseBirthdayService.fetchUserBookings(null);
    } catch (e) {
      debugPrint('BirthdayProvider.loadAll error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEventData(String eventId) async {
    _expenses = await BirthdayService.getEventExpenses(eventId);
    _tasks = await BirthdayService.getEventTasks(eventId);
    _guests = await BirthdayService.getEventGuests(eventId);
    _gifts = await BirthdayService.getEventGifts(eventId);
    _timeline = await BirthdayService.getEventTimeline(eventId);
    _memories = await BirthdayService.getEventMemories(eventId);
    _sharedPhotos = await SupabaseBirthdayService.fetchEventPhotos(eventId);
    notifyListeners();
  }

  void setActiveEvent(BirthdayEvent event) {
    _activeEvent = event;
    loadEventData(event.id);
  }

  // ===== SERVICE CART OPERATIONS =====
  bool isPackageInCart(String packageId) {
    return _serviceCart.any((item) => item.package.id == packageId);
  }

  BirthdayServiceCartItem? getCartItem(String packageId) {
    try {
      return _serviceCart.firstWhere((item) => item.package.id == packageId);
    } catch (_) {
      return null;
    }
  }

  void addOrUpdateCartItem({
    required BirthdayServicePackage package,
    int quantity = 25,
    List<BirthdayServiceAddon>? addons,
    String customNotes = '',
  }) {
    final existingIdx = _serviceCart.indexWhere((item) => item.package.id == package.id);
    if (existingIdx != -1) {
      _serviceCart[existingIdx] = BirthdayServiceCartItem(
        package: package,
        quantity: quantity,
        selectedAddons: addons ?? _serviceCart[existingIdx].selectedAddons,
        customNotes: customNotes.isNotEmpty ? customNotes : _serviceCart[existingIdx].customNotes,
      );
    } else {
      _serviceCart.add(BirthdayServiceCartItem(
        package: package,
        quantity: quantity,
        selectedAddons: addons ?? [],
        customNotes: customNotes,
      ));
    }
    notifyListeners();
  }

  void removeCartItem(String packageId) {
    _serviceCart.removeWhere((item) => item.package.id == packageId);
    notifyListeners();
  }

  void updateCartItemQuantity(String packageId, int newQuantity) {
    final item = getCartItem(packageId);
    if (item != null && newQuantity > 0) {
      item.quantity = newQuantity;
      notifyListeners();
    }
  }

  void toggleCartItemAddon(String packageId, BirthdayServiceAddon addon) {
    final item = getCartItem(packageId);
    if (item != null) {
      final hasAddon = item.selectedAddons.any((a) => a.id == addon.id);
      if (hasAddon) {
        item.selectedAddons.removeWhere((a) => a.id == addon.id);
      } else {
        item.selectedAddons.add(addon);
      }
      notifyListeners();
    }
  }

  void clearServiceCart() {
    _serviceCart.clear();
    notifyListeners();
  }

  // ===== BOOKING CALENDAR & SLOTS =====
  void selectDateAndSlot(DateTime date, BirthdayTimeSlot slot) {
    _selectedBookingDate = date;
    _selectedBookingSlot = slot;
    notifyListeners();
  }

  Future<bool> reserveSelectedSlot() async {
    if (_selectedBookingDate == null || _selectedBookingSlot == null) return false;
    final token = 'res_${DateTime.now().millisecondsSinceEpoch}';
    final success = await SupabaseBirthdayService.reserveSlotTemporary(
      date: _selectedBookingDate!,
      slot: _selectedBookingSlot!,
      token: token,
      duration: const Duration(minutes: 15),
    );
    if (success) {
      _activeReservationToken = token;
      notifyListeners();
    }
    return success;
  }

  Future<void> releaseActiveSlot() async {
    if (_selectedBookingDate != null && _selectedBookingSlot != null) {
      await SupabaseBirthdayService.releaseSlot(_selectedBookingDate!, _selectedBookingSlot!);
      _activeReservationToken = null;
      notifyListeners();
    }
  }

  // ===== BOOKING SUBMISSION & PAYMENT =====
  Future<bool> submitBookingAndPayment({
    required BirthdayBooking booking,
    required BirthdayPayment payment,
  }) async {
    final success = await SupabaseBirthdayService.submitBooking(
      booking: booking,
      payment: payment,
    );
    if (success) {
      _userBookings.insert(0, booking);
      _serviceCart.clear();
      _selectedBookingDate = null;
      _selectedBookingSlot = null;
      _activeReservationToken = null;
      notifyListeners();
    }
    return success;
  }

  // ===== SHARED GALLERY OPERATIONS =====
  Future<void> loadSharedPhotos(String eventId) async {
    _sharedPhotos = await SupabaseBirthdayService.fetchEventPhotos(eventId);
    notifyListeners();
  }

  Future<bool> addSharedPhoto(BirthdaySharedPhoto photo) async {
    final success = await SupabaseBirthdayService.addEventPhoto(photo);
    if (success) {
      _sharedPhotos.insert(0, photo);
      notifyListeners();
    }
    return success;
  }

  // ===== EVENT CRUD =====
  Future<void> createEvent(BirthdayEvent event) async {
    await BirthdayService.addEvent(event);
    _events.add(event);
    _activeEvent = event;
    await loadEventData(event.id);
    notifyListeners();
  }

  Future<void> addEvent(BirthdayEvent event) => createEvent(event);

  Future<void> updateEvent(BirthdayEvent event) async {
    await BirthdayService.updateEvent(event);
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx != -1) _events[idx] = event;
    if (_activeEvent?.id == event.id) _activeEvent = event;
    notifyListeners();
  }

  Future<void> deleteEvent(String eventId) async {
    await BirthdayService.deleteEvent(eventId);
    _events.removeWhere((e) => e.id == eventId);
    if (_activeEvent?.id == eventId) {
      _activeEvent = _events.isNotEmpty ? _events.first : null;
      if (_activeEvent != null) {
        await loadEventData(_activeEvent!.id);
      }
    }
    notifyListeners();
  }

  // ===== EXPENSE CRUD =====
  Future<void> addExpense(BirthdayExpense expense) async {
    await BirthdayService.addExpense(expense);
    _expenses.add(expense);
    notifyListeners();
  }

  Future<void> updateExpense(BirthdayExpense expense) async {
    await BirthdayService.updateExpense(expense);
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) _expenses[idx] = expense;
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    await BirthdayService.deleteExpense(expenseId);
    _expenses.removeWhere((e) => e.id == expenseId);
    notifyListeners();
  }

  // ===== TASK CRUD =====
  Future<void> addTask(BirthdayTask task) async {
    await BirthdayService.addTask(task);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> updateTask(BirthdayTask task) async {
    await BirthdayService.updateTask(task);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) _tasks[idx] = task;
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await BirthdayService.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx].isCompleted = !_tasks[idx].isCompleted;
      await BirthdayService.updateTask(_tasks[idx]);
      notifyListeners();
    }
  }

  // ===== GUEST CRUD =====
  Future<void> addGuest(BirthdayGuest guest) async {
    await BirthdayService.addGuest(guest);
    _guests.add(guest);
    notifyListeners();
  }

  Future<void> updateGuest(BirthdayGuest guest) async {
    await BirthdayService.updateGuest(guest);
    final idx = _guests.indexWhere((g) => g.id == guest.id);
    if (idx != -1) _guests[idx] = guest;
    notifyListeners();
  }

  Future<void> deleteGuest(String guestId) async {
    await BirthdayService.deleteGuest(guestId);
    _guests.removeWhere((g) => g.id == guestId);
    notifyListeners();
  }

  // ===== GIFT CRUD =====
  Future<void> addGift(BirthdayGift gift) async {
    await BirthdayService.addGift(gift);
    _gifts.add(gift);
    notifyListeners();
  }

  Future<void> updateGift(BirthdayGift gift) async {
    await BirthdayService.updateGift(gift);
    final idx = _gifts.indexWhere((g) => g.id == gift.id);
    if (idx != -1) _gifts[idx] = gift;
    notifyListeners();
  }

  Future<void> deleteGift(String giftId) async {
    await BirthdayService.deleteGift(giftId);
    _gifts.removeWhere((g) => g.id == giftId);
    notifyListeners();
  }

  // ===== TIMELINE CRUD =====
  Future<void> addTimelineItem(BirthdayTimelineItem item) async {
    await BirthdayService.addTimelineItem(item);
    _timeline.add(item);
    _timeline.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifyListeners();
  }

  Future<void> updateTimelineItem(BirthdayTimelineItem item) async {
    await BirthdayService.updateTimelineItem(item);
    final idx = _timeline.indexWhere((t) => t.id == item.id);
    if (idx != -1) _timeline[idx] = item;
    notifyListeners();
  }

  Future<void> deleteTimelineItem(String itemId) async {
    await BirthdayService.deleteTimelineItem(itemId);
    _timeline.removeWhere((t) => t.id == itemId);
    notifyListeners();
  }

  // ===== MEMORY CRUD =====
  Future<void> addMemory(BirthdayMemory memory) async {
    await BirthdayService.addMemory(memory);
    _memories.add(memory);
    notifyListeners();
  }

  Future<void> deleteMemory(String memoryId) async {
    await BirthdayService.deleteMemory(memoryId);
    _memories.removeWhere((m) => m.id == memoryId);
    notifyListeners();
  }
}
