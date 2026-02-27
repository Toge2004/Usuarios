import '../models/user_model.dart';
import '../services/db_service.dart';

class UserController {
  // Usar la instancia singleton del DbService
  final db = DbService();

  Future<List<User>> getUsers() => db.getUsers();
  
  Future<int> insertUser(User u) => db.insertUser(u);
  
  Future<int> updateUser(User u) => db.updateUser(u);
  
  Future<int> deleteUser(int id) => db.deleteUser(id);
}
