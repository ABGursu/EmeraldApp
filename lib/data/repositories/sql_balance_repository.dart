import '../local_db/database_helper.dart';
import '../models/budget_goal_model.dart';
import '../models/tag_model.dart';
import '../models/transaction_model.dart';
import '../repositories/i_balance_repository.dart';
import '../../utils/id_generator.dart';

class SqlBalanceRepository implements IBalanceRepository {
  final DatabaseHelper _dbHelper;

  SqlBalanceRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<String> createTag(TagModel tag) async {
    final db = await _dbHelper.database;
    final id = tag.id.isNotEmpty ? tag.id : generateId();
    await db.insert('tags', tag.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateTag(TagModel tag) async {
    final db = await _dbHelper.database;
    return db.update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  @override
  Future<int> deleteTag(String id) async {
    final db = await _dbHelper.database;
    return db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<TagModel>> getAllTags() async {
    final db = await _dbHelper.database;
    final result = await db.query('tags', orderBy: 'created_at DESC');
    return result.map(TagModel.fromMap).toList();
  }

  @override
  Future<String> createTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    final id = transaction.id.isNotEmpty ? transaction.id : generateId();
    await db.insert('transactions', transaction.copyWith(id: id).toMap());
    return id;
  }

  @override
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteTransaction(String id) async {
    final db = await _dbHelper.database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<TransactionModel>> getTransactions({String? tagId}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: tagId != null ? 'tag_id = ?' : null,
      whereArgs: tagId != null ? [tagId] : null,
      orderBy: 'date DESC',
    );
    return result.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<void> setBudget(String monthYear, double amount) async {
    final db = await _dbHelper.database;
    // Check if budget exists for this month
    final existing = await db.query(
      'budget_goals',
      where: 'month_year = ?',
      whereArgs: [monthYear],
    );

    if (existing.isEmpty) {
      // Create new budget
      final budget = BudgetGoalModel(
        id: generateId(),
        monthYear: monthYear,
        amount: amount,
      );
      await db.insert('budget_goals', budget.toMap());
    } else {
      // Update existing budget
      await db.update(
        'budget_goals',
        {'amount': amount},
        where: 'month_year = ?',
        whereArgs: [monthYear],
      );
    }
  }

  @override
  Future<double?> getBudget(String monthYear) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'budget_goals',
      where: 'month_year = ?',
      whereArgs: [monthYear],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return BudgetGoalModel.fromMap(result.first).amount;
  }

  @override
  Future<void> resetAll() async {
    final db = await _dbHelper.database;
    await db.delete('transactions');
    await db.delete('budget_goals');
    // Tags are kept on purpose
  }
}
