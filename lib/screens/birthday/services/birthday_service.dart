import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/birthday/birthday_event.dart';
import '../../../models/birthday/birthday_expense.dart';
import '../../../models/birthday/birthday_task.dart';
import '../../../models/birthday/birthday_guest.dart';
import '../../../models/birthday/birthday_gift.dart';
import '../../../models/birthday/birthday_timeline_item.dart';
import '../../../models/birthday/birthday_memory.dart';

/// Local persistence service for all birthday module data.
/// Uses shared_preferences for JSON storage.
class BirthdayService {
  static const String _eventsKey = 'birthday_events';
  static const String _expensesKey = 'birthday_expenses';
  static const String _tasksKey = 'birthday_tasks';
  static const String _guestsKey = 'birthday_guests';
  static const String _giftsKey = 'birthday_gifts';
  static const String _timelineKey = 'birthday_timeline';
  static const String _memoriesKey = 'birthday_memories';

  // ===== EVENTS =====
  static Future<List<BirthdayEvent>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_eventsKey) ?? [];
    return data.map((e) => BirthdayEvent.decode(e)).toList();
  }

  static Future<void> saveEvents(List<BirthdayEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_eventsKey, events.map((e) => e.encode()).toList());
  }

  static Future<void> addEvent(BirthdayEvent event) async {
    final events = await loadEvents();
    events.add(event);
    await saveEvents(events);
  }

  static Future<void> updateEvent(BirthdayEvent event) async {
    final events = await loadEvents();
    final idx = events.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      events[idx] = event;
      await saveEvents(events);
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    final events = await loadEvents();
    events.removeWhere((e) => e.id == eventId);
    await saveEvents(events);
    // Also delete related data
    await _deleteRelatedData(eventId);
  }

  static Future<void> _deleteRelatedData(String eventId) async {
    final expenses = await loadExpenses();
    expenses.removeWhere((e) => e.eventId == eventId);
    await saveExpenses(expenses);

    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.eventId == eventId);
    await saveTasks(tasks);

    final guests = await loadGuests();
    guests.removeWhere((g) => g.eventId == eventId);
    await saveGuests(guests);

    final gifts = await loadGifts();
    gifts.removeWhere((g) => g.eventId == eventId);
    await saveGifts(gifts);

    final timeline = await loadTimeline();
    timeline.removeWhere((t) => t.eventId == eventId);
    await saveTimeline(timeline);

    final memories = await loadMemories();
    memories.removeWhere((m) => m.eventId == eventId);
    await saveMemories(memories);
  }

  // ===== EXPENSES =====
  static Future<List<BirthdayExpense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_expensesKey) ?? [];
    return data.map((e) => BirthdayExpense.decode(e)).toList();
  }

  static Future<void> saveExpenses(List<BirthdayExpense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_expensesKey, expenses.map((e) => e.encode()).toList());
  }

  static Future<List<BirthdayExpense>> getEventExpenses(String eventId) async {
    final all = await loadExpenses();
    return all.where((e) => e.eventId == eventId).toList();
  }

  static Future<void> addExpense(BirthdayExpense expense) async {
    final expenses = await loadExpenses();
    expenses.add(expense);
    await saveExpenses(expenses);
  }

  static Future<void> updateExpense(BirthdayExpense expense) async {
    final expenses = await loadExpenses();
    final idx = expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      expenses[idx] = expense;
      await saveExpenses(expenses);
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    final expenses = await loadExpenses();
    expenses.removeWhere((e) => e.id == expenseId);
    await saveExpenses(expenses);
  }

  // ===== TASKS =====
  static Future<List<BirthdayTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_tasksKey) ?? [];
    return data.map((e) => BirthdayTask.decode(e)).toList();
  }

  static Future<void> saveTasks(List<BirthdayTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tasksKey, tasks.map((e) => e.encode()).toList());
  }

  static Future<List<BirthdayTask>> getEventTasks(String eventId) async {
    final all = await loadTasks();
    return all.where((t) => t.eventId == eventId).toList();
  }

  static Future<void> addTask(BirthdayTask task) async {
    final tasks = await loadTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  static Future<void> updateTask(BirthdayTask task) async {
    final tasks = await loadTasks();
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      tasks[idx] = task;
      await saveTasks(tasks);
    }
  }

  static Future<void> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  // ===== GUESTS =====
  static Future<List<BirthdayGuest>> loadGuests() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_guestsKey) ?? [];
    return data.map((e) => BirthdayGuest.decode(e)).toList();
  }

  static Future<void> saveGuests(List<BirthdayGuest> guests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_guestsKey, guests.map((e) => e.encode()).toList());
  }

  static Future<List<BirthdayGuest>> getEventGuests(String eventId) async {
    final all = await loadGuests();
    return all.where((g) => g.eventId == eventId).toList();
  }

  static Future<void> addGuest(BirthdayGuest guest) async {
    final guests = await loadGuests();
    guests.add(guest);
    await saveGuests(guests);
  }

  static Future<void> updateGuest(BirthdayGuest guest) async {
    final guests = await loadGuests();
    final idx = guests.indexWhere((g) => g.id == guest.id);
    if (idx != -1) {
      guests[idx] = guest;
      await saveGuests(guests);
    }
  }

  static Future<void> deleteGuest(String guestId) async {
    final guests = await loadGuests();
    guests.removeWhere((g) => g.id == guestId);
    await saveGuests(guests);
  }

  // ===== GIFTS =====
  static Future<List<BirthdayGift>> loadGifts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_giftsKey) ?? [];
    return data.map((e) => BirthdayGift.decode(e)).toList();
  }

  static Future<void> saveGifts(List<BirthdayGift> gifts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_giftsKey, gifts.map((e) => e.encode()).toList());
  }

  static Future<List<BirthdayGift>> getEventGifts(String eventId) async {
    final all = await loadGifts();
    return all.where((g) => g.eventId == eventId).toList();
  }

  static Future<void> addGift(BirthdayGift gift) async {
    final gifts = await loadGifts();
    gifts.add(gift);
    await saveGifts(gifts);
  }

  static Future<void> updateGift(BirthdayGift gift) async {
    final gifts = await loadGifts();
    final idx = gifts.indexWhere((g) => g.id == gift.id);
    if (idx != -1) {
      gifts[idx] = gift;
      await saveGifts(gifts);
    }
  }

  static Future<void> deleteGift(String giftId) async {
    final gifts = await loadGifts();
    gifts.removeWhere((g) => g.id == giftId);
    await saveGifts(gifts);
  }

  // ===== TIMELINE =====
  static Future<List<BirthdayTimelineItem>> loadTimeline() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_timelineKey) ?? [];
    return data.map((e) => BirthdayTimelineItem.decode(e)).toList();
  }

  static Future<void> saveTimeline(List<BirthdayTimelineItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_timelineKey, items.map((e) => e.encode()).toList());
  }

  static Future<List<BirthdayTimelineItem>> getEventTimeline(String eventId) async {
    final all = await loadTimeline();
    return all.where((t) => t.eventId == eventId).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  static Future<void> addTimelineItem(BirthdayTimelineItem item) async {
    final items = await loadTimeline();
    items.add(item);
    await saveTimeline(items);
  }

  static Future<void> updateTimelineItem(BirthdayTimelineItem item) async {
    final items = await loadTimeline();
    final idx = items.indexWhere((t) => t.id == item.id);
    if (idx != -1) {
      items[idx] = item;
      await saveTimeline(items);
    }
  }

  static Future<void> deleteTimelineItem(String itemId) async {
    final items = await loadTimeline();
    items.removeWhere((t) => t.id == itemId);
    await saveTimeline(items);
  }

  // ===== MEMORIES =====
  static Future<List<BirthdayMemory>> loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_memoriesKey) ?? [];
    return data.map((e) => BirthdayMemory.decode(e)).toList();
  }

  static Future<void> saveMemories(List<BirthdayMemory> memories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_memoriesKey, memories.map((e) => e.encode()).toList());
  }

  static Future<List<BirthdayMemory>> getEventMemories(String eventId) async {
    final all = await loadMemories();
    return all.where((m) => m.eventId == eventId).toList();
  }

  static Future<void> addMemory(BirthdayMemory memory) async {
    final memories = await loadMemories();
    memories.add(memory);
    await saveMemories(memories);
  }

  static Future<void> deleteMemory(String memoryId) async {
    final memories = await loadMemories();
    memories.removeWhere((m) => m.id == memoryId);
    await saveMemories(memories);
  }
}
