// screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/transaction_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Income',
                  '₦${provider.totalIncome.toStringAsFixed(2)}',
                  Colors.green,
                  Icons.arrow_upward,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Expenses',
                  '₦${provider.totalExpenses.toStringAsFixed(2)}',
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Net Profit',
                  '₦${provider.netProfit.toStringAsFixed(2)}',
                  provider.netProfit >= 0 ? Colors.blue : Colors.orange,
                  provider.netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Outstanding Debts',
                  '₦${provider.totalDebts.toStringAsFixed(2)}',
                  Colors.purple,
                  Icons.people,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Quick Actions
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(context, Icons.add, 'Record Sale', Colors.green, () {
                Navigator.pushNamed(context, '/add-transaction', arguments: {'type': 'income'});
              }),
              _buildActionButton(context, Icons.remove, 'Record Expense', Colors.red, () {
                Navigator.pushNamed(context, '/add-transaction', arguments: {'type': 'expense'});
              }),
              _buildActionButton(context, Icons.people, 'Debtors', Colors.purple, () {
                Navigator.pushNamed(context, '/debtors');
              }),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Weekly Cash Flow Chart
          Text('Weekly Cash Flow', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: _buildCashFlowChart(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20), // Reduced icon size
                SizedBox(width: 8),
                Text(
                  title, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value, 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14, // Reduced font size
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: Colors.white,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.all(16),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
  
  Widget _buildCashFlowChart(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    // Get last 7 days transactions
    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));
    
    final dailyIncome = List<double>.filled(7, 0);
    final dailyExpenses = List<double>.filled(7, 0);
    
    for (var transaction in provider.transactions) {
      if (transaction.date.isAfter(weekAgo)) {
        final dayIndex = 6 - now.difference(transaction.date).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          if (transaction.type == 'income') {
            dailyIncome[dayIndex] += transaction.amount;
          } else {
            dailyExpenses[dayIndex] += transaction.amount;
          }
        }
      }
    }
    
    final maxY = [...dailyIncome, ...dailyExpenses].reduce((a, b) => a > b ? a : b) * 1.1;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('E').format(date)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('₦${value.toInt()}');
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: [
          for (int i = 0; i < 7; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyIncome[i],
                  color: Colors.green,
                  width: 12,
                ),
                BarChartRodData(
                  toY: dailyExpenses[i],
                  color: Colors.red,
                  width: 12,
                ),
              ],
            ),
        ],
      ),
    );
  }
}