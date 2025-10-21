import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cbook/providers/business_book_provider.dart';
import 'package:cbook/providers/transaction_provider.dart';
import 'package:cbook/models/business_book.dart'; // Add this import
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class BusinessStatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BusinessBookProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final book = bookProvider.currentBook;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Business Statistics')),
        body: Center(child: Text('No business book selected')),
      );
    }

    final income = transactionProvider.totalIncome;
    final expenses = transactionProvider.totalExpenses;
    final profit = income - expenses;
    final profitMargin = income > 0 ? (profit / income) * 100 : 0.00;

    return Scaffold(
      appBar: AppBar(title: Text('Business Statistics')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCards(income, expenses, profit, profitMargin),
            
            SizedBox(height: 24),
            
            // Revenue Chart
            _buildRevenueChart(transactionProvider),
            
            SizedBox(height: 24),
            
            // Expense Breakdown
            _buildExpenseBreakdown(transactionProvider),
            
            SizedBox(height: 24),
            
            // Performance Metrics
            _buildPerformanceMetrics(book, transactionProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expenses, double profit, double profitMargin) {
    return GridView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      children: [
        _buildMetricCard('Total Income', income, Colors.green, Icons.arrow_upward),
        _buildMetricCard('Total Expenses', expenses, Colors.red, Icons.arrow_downward),
        _buildMetricCard('Net Profit', profit, profit >= 0 ? Colors.blue : Colors.orange, 
                         profit >= 0 ? Icons.trending_up : Icons.trending_down),
        _buildMetricCard('Profit Margin', profitMargin, Colors.purple, Icons.percent),
      ],
    );
  }

  Widget _buildMetricCard(String title, double value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color), // Reduced from 32 to 28
            SizedBox(height: 6), // Reduced from 8 to 6
            Text(
              title,
              style: TextStyle(fontSize: 8, color: Colors.grey[600]), // Reduced from 12 to 11
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3), // Reduced from 4 to 3
            Text(
              value is double ? '₦${NumberFormat('#,##0.00').format(value)}' : '${value.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), // Reduced from 16 to 14
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(TransactionProvider provider) {
    final monthlyData = provider.monthlySummary;
    
    // Convert num values to double for the chart
    final incomeValue = (monthlyData['income'] ?? 0).toDouble();
    final expenseValue = (monthlyData['expense'] ?? 0).toDouble();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(show: false),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: incomeValue, color: Colors.green),
                        BarChartRodData(toY: expenseValue, color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Income'),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.red),
                    SizedBox(width: 4),
                    Text('Expenses'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdown(TransactionProvider provider) {
    final expensesByCategory = provider.getTransactionsByCategory('expense');
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            if (expensesByCategory.isEmpty)
              Text('No expenses recorded yet', style: TextStyle(color: Colors.grey)),
            ...expensesByCategory.entries.map((entry) => 
              _buildExpenseItem(entry.key, entry.value)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(String category, double amount) {
    return ListTile(
      leading: Icon(Icons.category, color: Colors.orange),
      title: Text(category),
      trailing: Text('₦${NumberFormat('#,##0.00').format(amount)}', 
                   style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPerformanceMetrics(BusinessBook book, TransactionProvider provider) {
    final avgTransaction = provider.transactions.isNotEmpty 
        ? (provider.totalIncome + provider.totalExpenses) / provider.transactions.length 
        : 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildMetricRow('Active Customers', provider.debtors.length.toString()),
            _buildMetricRow('Active Suppliers', provider.creditors.length.toString()),
            _buildMetricRow('Total Transactions', provider.transactions.length.toString()),
            _buildMetricRow('Average Transaction', 
                '₦${NumberFormat('#,##0.00').format(avgTransaction)}'),
            _buildMetricRow('Business Type', book.businessType),
            _buildMetricRow('Currency', book.currency),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}