// screens/guide_screen.dart
import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('How to Use CBook'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '📊 Getting Started',
              children: [
                _buildStep(
                  number: 1,
                  text: 'Create a Business Book from the main screen',
                ),
                _buildStep(
                  number: 2,
                  text: 'Set up your business details and currency (₦)',
                ),
                _buildStep(
                  number: 3,
                  text: 'Add team members to collaborate',
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            _buildSection(
              title: '💼 Managing Transactions',
              children: [
                _buildStep(
                  number: 1,
                  text: 'Tap the + button to add new transactions',
                ),
                _buildStep(
                  number: 2,
                  text: 'Categorize transactions as Income or Expense',
                ),
                _buildStep(
                  number: 3,
                  text: 'Add VAT (7.5%) for Nigerian compliance',
                ),
                _buildStep(
                  number: 4,
                  text: 'Use credit transactions to track debts',
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            _buildSection(
              title: '👥 Managing Contacts',
              children: [
                _buildStep(
                  number: 1,
                  text: 'Debtors: People who owe you money',
                ),
                _buildStep(
                  number: 2,
                  text: 'Creditors: People you owe money to',
                ),
                _buildStep(
                  number: 3,
                  text: 'Track balances and payment history',
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            _buildSection(
              title: '📈 Understanding Reports',
              children: [
                _buildStep(
                  number: 1,
                  text: 'Dashboard: Overview of your finances',
                ),
                _buildStep(
                  number: 2,
                  text: 'Monthly summaries and profit calculations',
                ),
                _buildStep(
                  number: 3,
                  text: 'VAT tracking for Nigerian tax compliance',
                ),
                _buildStep(
                  number: 4,
                  text: 'Financial health indicators',
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            _buildSection(
              title: '☁️ Cloud Sync',
              children: [
                _buildStep(
                  number: 1,
                  text: 'Automatic backup',
                ),
                _buildStep(
                  number: 2,
                  text: 'Access your data from multiple devices',
                ),
                _buildStep(
                  number: 3,
                  text: 'Secure encryption for your financial data',
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            _buildSection(
              title: '🎯 Tips for Businesses',
              children: [
                _buildStep(
                  number: 1,
                  text: 'Always enable VAT for sales transactions',
                ),
                _buildStep(
                  number: 2,
                  text: 'Keep track of debtors for better cash flow',
                ),
                _buildStep(
                  number: 3,
                  text: 'Regularly back up your data',
                ),
                _buildStep(
                  number: 4,
                  text: 'Use categories that match Nigerian business types',
                ),
              ],
            ),
            
            SizedBox(height: 32),
            
            Center(
              child: Text(
                'Need more help? Contact support@cbook.ng',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildStep({required int number, required String text}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}