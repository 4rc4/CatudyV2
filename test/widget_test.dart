import 'package:catudy_app/app/catudy_app.dart';
import 'package:catudy_app/app/demo/catudy_demo_store.dart';
import 'package:catudy_app/shared/widgets/floating_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders Catudy shell with bottom navigation', (tester) async {
    await _pumpCatudy(tester);

    expect(find.text('Odak Zamanı'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
    expect(find.byIcon(Icons.query_stats_outlined), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Stats'), findsNothing);
    expect(find.text('Calendar'), findsNothing);
    expect(find.text('Pet'), findsWidgets);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('redirects social into community friends surface', (
    tester,
  ) async {
    await _pumpCatudy(tester, initialLocation: '/social');

    expect(find.text('Topluluk'), findsOneWidget);
    expect(find.text('Sıralama'), findsOneWidget);
    expect(find.text('Kod ile arkadaş ekle'), findsOneWidget);
    expect(find.text('Kullanıcı kodu'), findsOneWidget);
    expect(find.text('Arkadaşlar'), findsWidgets);
    expect(find.text('Odak panosu'), findsNothing);
    expect(find.byIcon(Icons.meeting_room_rounded), findsOneWidget);
    expect(find.byIcon(Icons.visibility_rounded), findsNothing);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('redirects leaderboard into community ranking surface', (
    tester,
  ) async {
    await _pumpCatudy(tester, initialLocation: '/leaderboard');

    expect(find.text('Topluluk'), findsOneWidget);
    expect(find.text('Odak Süresi Sıralaması'), findsOneWidget);
    expect(find.text('Arkadaşlar'), findsOneWidget);
    expect(find.text('Sıralama'), findsOneWidget);
  });

  testWidgets('renders community lobbies and preserves lobby redirect', (
    tester,
  ) async {
    await _pumpCatudy(tester, initialLocation: '/community?tab=lobbies');

    expect(find.text('Topluluk'), findsOneWidget);
    expect(find.text('Lobiler'), findsOneWidget);
    expect(find.text('Lobi kur veya katıl'), findsOneWidget);
    expect(find.text('Online lobi kur'), findsWidgets);
    expect(find.text('Koda katıl'), findsWidgets);

    await _pumpCatudy(tester, initialLocation: '/lobby');

    expect(find.text('Topluluk'), findsOneWidget);
    expect(find.text('Lobi kur veya katıl'), findsOneWidget);
  });

  testWidgets('renders one-surface focus composer', (tester) async {
    await _pumpCatudy(tester, initialLocation: '/focus/start');

    expect(find.text('Odağı Başlat'), findsOneWidget);
    expect(find.text('Başlamaya hazır'), findsOneWidget);
    expect(find.text('Kategori Seç'), findsOneWidget);
    expect(find.text('Süre Seç'), findsOneWidget);
    expect(find.text('Daha fazla ayar'), findsOneWidget);
  });

  testWidgets('renders Stats range controls', (tester) async {
    await _pumpCatudy(tester, initialLocation: '/stats');

    expect(find.text('Kategori Dağılımı'), findsOneWidget);
    expect(find.text('Hafta'), findsOneWidget);
    expect(find.text('Ay'), findsOneWidget);
    expect(find.text('Tümü'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });

  testWidgets('renders category flow with large add toggle', (tester) async {
    await _pumpCatudy(tester, initialLocation: '/focus/category');

    expect(find.text('Kategori Seç'), findsOneWidget);
    expect(find.text('Yeni kategori ekle'), findsOneWidget);

    await tester.tap(find.text('Yeni kategori ekle'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Özel kategori'), findsOneWidget);
  });

  testWidgets('renders calendar month and selected day details', (
    tester,
  ) async {
    await _pumpCatudy(tester, initialLocation: '/calendar');

    expect(find.text('Takvim'), findsOneWidget);
    expect(find.text('Manuel Ekle'), findsOneWidget);
    expect(find.text('Hatırlatma'), findsOneWidget);
    expect(find.text('Pzt'), findsOneWidget);
  });

  testWidgets('renders pet room, shop, inventory, and profile pages', (
    tester,
  ) async {
    await _pumpCatudy(tester, initialLocation: '/pet-room');
    expect(find.text('Pet Odası'), findsOneWidget);
    expect(find.text('Mochi Odası'), findsOneWidget);
    expect(find.byType(FloatingMascot), findsOneWidget);
    expect(find.text('Mağaza'), findsOneWidget);
    expect(find.text('Envanter'), findsOneWidget);

    await _pumpCatudy(tester, initialLocation: '/shop');
    expect(find.text('Mağaza'), findsOneWidget);

    await _pumpCatudy(tester, initialLocation: '/inventory');
    expect(find.text('Envanter'), findsOneWidget);

    await _pumpCatudy(tester, initialLocation: '/profile');
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('İlgi Alanları / Kategoriler'), findsOneWidget);
    expect(find.text('Koleksiyon'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
  });

  testWidgets('renders settings with language support', (tester) async {
    await _pumpCatudy(tester, initialLocation: '/settings');

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Dil'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
  });

  testWidgets('switches visible settings copy to English', (tester) async {
    await _pumpCatudy(tester, initialLocation: '/settings');

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Pet notifications'), findsOneWidget);
    expect(find.text('Save settings'), findsNothing);
  });

  testWidgets('renders Online MVP auth options without Apple', (tester) async {
    await _pumpCatudy(tester, initialLocation: '/auth');

    expect(find.byIcon(Icons.mail_rounded), findsOneWidget);
    expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apple_rounded), findsNothing);
  });

  testWidgets('renders premium, season pass, and crates routes', (
    tester,
  ) async {
    await _pumpCatudy(tester, initialLocation: '/plus');
    expect(find.text('Catudy Plus'), findsOneWidget);
    expect(find.text('Buddy Pass'), findsOneWidget);

    await _pumpCatudy(tester, initialLocation: '/season');
    expect(find.text('Focus Pass'), findsOneWidget);
    expect(find.text('Ücretsiz yol'), findsOneWidget);

    await _pumpCatudy(tester, initialLocation: '/crates');
    expect(find.text('Kutular'), findsOneWidget);
    expect(find.text('Koleksiyon'), findsOneWidget);
  });
}

Future<void> _pumpCatudy(
  WidgetTester tester, {
  String initialLocation = '/',
}) async {
  SharedPreferences.setMockInitialValues({});
  catudyDemoStore.updateSettings(
    name: 'Guest Cat',
    apiUrl: 'http://127.0.0.1:5099',
    dnd: true,
    petNotifications: true,
    language: 'tr',
    themeMode: 'system',
  );
  catudyDemoStore.markIntroTourSeen();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pumpWidget(
    ProviderScope(child: CatudyApp(initialLocation: initialLocation)),
  );
  await tester.pump(const Duration(milliseconds: 800));
}
