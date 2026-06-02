import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/darkkick_colors.dart';
import '../models/chat_model.dart';
import 'security_screen.dart';
import 'profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedFilterIndex = 1; // "Личные" активна по умолчанию

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkKickColors.darkBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(),
            _buildStoriesList(),
            _buildFilterTabs(),
            _buildChatsList(),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: DarkKickColors.darkBackground,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: DarkKickColors.textPrimary),
        onPressed: () {},
      ),
      title: Text(
        'DARKKICK',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: DarkKickColors.textPrimary,
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DarkKickColors.mediumGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DarkKickColors.neonPurple, width: 2),
          ),
          child: Icon(Icons.edit_square, color: DarkKickColors.neonPurple, size: 20),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: DarkKickColors.mediumGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
            Icon(Icons.search, color: DarkKickColors.lightGray, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: TextStyle(color: DarkKickColors.lightGray),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(color: DarkKickColors.textPrimary),
              ),
            ),
            Icon(Icons.tune, color: DarkKickColors.lightGray, size: 20),
            SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: mockStories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DarkKickColors.neonPurple,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        color: DarkKickColors.neonPurple,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Создать',
                      style: TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }

            final story = mockStories[index - 1];
            return Padding(
              padding: EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DarkKickColors.mediumGray,
                      boxShadow: [
                        BoxShadow(
                          color: DarkKickColors.neonPurple.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        story.avatar,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: DarkKickColors.neonPurple,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    story.name,
                    style: TextStyle(
                      color: DarkKickColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Все', 'Личные', 'Группы', 'Каналы'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          filters.length,
          (index) => Padding(
            padding: EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedFilterIndex == index
                      ? DarkKickColors.neonPurple
                      : Colors.transparent,
                  border: Border.all(
                    color: _selectedFilterIndex == index
                        ? DarkKickColors.neonPurple
                        : DarkKickColors.divider,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: _selectedFilterIndex == index
                        ? DarkKickColors.darkBackground
                        : DarkKickColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: mockChats.length,
      separatorBuilder: (_, __) => Divider(
        color: DarkKickColors.divider,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final chat = mockChats[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DarkKickColors.mediumGray,
                  boxShadow: [
                    BoxShadow(
                      color: DarkKickColors.neonPurple.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    chat.avatar ?? 'G',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: DarkKickColors.neonPurple,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DarkKickColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      chat.lastMessage,
                      style: TextStyle(
                        color: DarkKickColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              // Time and badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${chat.lastMessageTime.hour.toString().padLeft(2, '0')}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: DarkKickColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (chat.unreadCount > 0)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DarkKickColors.neonPurple,
                      ),
                      child: Center(
                        child: Text(
                          chat.unreadCount.toString(),
                          style: TextStyle(
                            color: DarkKickColors.darkBackground,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: DarkKickColors.divider),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: DarkKickColors.darkBackground,
        selectedItemColor: DarkKickColors.neonPurple,
        unselectedItemColor: DarkKickColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_outlined),
            activeIcon: Icon(Icons.phone),
            label: 'Звонки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Люди',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        onTap: (index) {
          if (index == 3) {
            // Navigate to profile screen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            );
          } else if (index == 2) {
            // Navigate to security screen (as placeholder for "Люди")
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SecurityScreen()),
            );
          }
        },
      ),
    );
  }
}
