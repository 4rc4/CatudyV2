import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _controller = TextEditingController();
  Color _selectedColor = CatudyColors.violet;
  bool _showAddCategory = false;

  static const _palette = [
    CatudyColors.violet,
    CatudyColors.teal,
    CatudyColors.coral,
    CatudyColors.yellow,
    CatudyColors.lavender,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('focus.categoryTitle'),
        showBack: true,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: store.categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) {
              final category = store.categories[index];
              return _CategoryCard(category: category);
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _showAddCategory = !_showAddCategory),
            icon: Icon(
              _showAddCategory ? Icons.close_rounded : Icons.add_rounded,
            ),
            label: Text(
              _showAddCategory
                  ? store.t('focus.addCategoryClose')
                  : store.t('focus.addCategoryOpen'),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _showAddCategory
                ? Padding(
                    key: const ValueKey('add-category'),
                    padding: const EdgeInsets.only(top: 14),
                    child: CatudyPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.t('focus.customCategory'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: CatudyColors.blue,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: store.t('focus.categoryName'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            children: [
                              for (final color in _palette)
                                InkWell(
                                  onTap: () =>
                                      setState(() => _selectedColor = color),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _selectedColor == color
                                            ? CatudyColors.blue
                                            : Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () {
                              store.addCategory(
                                _controller.text,
                                _selectedColor,
                              );
                              _controller.clear();
                              setState(() => _showAddCategory = false);
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: Text(store.t('focus.addCategory')),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/focus/duration'),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(store.t('common.continue')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final FocusCategory category;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final selected = store.selectedCategoryId == category.id;
        return InkWell(
          onTap: () => store.selectCategory(category.id),
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? category.color.withValues(alpha: 0.20)
                  : CatudyColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? category.color
                    : CatudyColors.violet.withValues(alpha: 0.18),
                width: selected ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: category.color.withValues(
                    alpha: selected ? 0.18 : 0.08,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconFor(category.id),
                    color: category.color,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selected
                      ? store.t('common.selected')
                      : store.t('focus.tapSelect'),
                  style: const TextStyle(
                    color: CatudyColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'work' => Icons.laptop_mac_rounded,
      'read' => Icons.menu_book_rounded,
      'math' => Icons.calculate_rounded,
      _ => Icons.school_rounded,
    };
  }
}
