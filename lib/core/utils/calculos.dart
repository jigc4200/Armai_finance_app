import '../../models/transaction_model.dart';
import '../../models/portfolio_model.dart';

double calcularBalance(List<Transaction> transacciones) {
  final ingresos = transacciones
      .where((t) => t.tipo == 'ingreso')
      .fold<double>(0, (sum, t) => sum + t.monto);
  final gastos = transacciones
      .where((t) => t.tipo == 'gasto')
      .fold<double>(0, (sum, t) => sum + t.monto);
  return ingresos - gastos;
}

double calcularROI(Portfolio cartera) {
  if (cartera.totalInvertido <= 0) return 0;
  return ((cartera.totalRetorno - cartera.totalInvertido) /
          cartera.totalInvertido) *
      100;
}

Map<String, double> gastosPorCategoria(List<Transaction> transacciones) {
  final map = <String, double>{};
  for (final t in transacciones.where((t) => t.tipo == 'gasto')) {
    map.update(t.categoria, (v) => v + t.monto, ifAbsent: () => t.monto);
  }
  return map;
}
