import 'package:flutter/material.dart';
import '../layouts/smart_grid.dart';
import '../core/design_system.dart';
import '../components/palace/brief_palace_config.dart';

/// 智能九宫格演示页面 — 简介模式布局
class SmartGridDemo extends StatefulWidget {
  const SmartGridDemo({super.key});

  @override
  State<SmartGridDemo> createState() => _SmartGridDemoState();
}

class _SmartGridDemoState extends State<SmartGridDemo> {
  int? _selectedPalaceIndex;
  bool _showDiGod = false;
  bool _showYinGan = false;
  bool _showAnGan = false;

  final List<_SizePreset> _sizePresets = const [
    _SizePreset('小 (72px)', 240),
    _SizePreset('中 (96px)', 320),
    _SizePreset('大 (120px)', 400),
  ];
  int _selectedSizeIndex = 1;

  BriefPalaceConfig get _config => BriefPalaceConfig(
    showDiGod: _showDiGod,
    showYinGan: _showYinGan,
    showAnGan: _showAnGan,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorSystem.background,
      appBar: AppBar(
        title: const Text('奇门遁甲 — 简介模式布局'),
        backgroundColor: ColorSystem.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 配置面板 ───────────────────────────────────────────
                _buildConfigPanel(),
                const SizedBox(height: 24),

                // ── 尺寸切换 ──────────────────────────────────────────
                _buildSizePicker(),
                const SizedBox(height: 24),

                // ── 九宫格主体 ────────────────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ColorSystem.surface,
                      borderRadius: QiMenRadius.lg,
                      boxShadow: [Shadows.lg],
                    ),
                    child: SmartQiMenGrid(
                      palaces: PalaceData.generateSampleData(),
                      selectedIndex: _selectedPalaceIndex,
                      briefConfig: _config,
                      maxGridSize: _sizePresets[_selectedSizeIndex].gridSize
                          .toDouble(),
                      onPalaceTap: (index) {
                        setState(() => _selectedPalaceIndex = index);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── 选中宫位详情 ───────────────────────────────────────
                if (_selectedPalaceIndex != null) _buildSelectedInfo(),

                const SizedBox(height: 24),

                // ── 布局说明 ───────────────────────────────────────────
                _buildLegend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 配置面板 ────────────────────────────────────────────────────────────────

  Widget _buildConfigPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorSystem.surface,
        borderRadius: QiMenRadius.md,
        border: Border.all(
          color: ColorSystem.textTertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BriefPalaceConfig 配置开关',
            style: QiMenTypography.labelLarge.copyWith(
              color: ColorSystem.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggle(
                  label: '显示地八神',
                  subtitle: 'showDiGod',
                  value: _showDiGod,
                  onChanged: (v) => setState(() => _showDiGod = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggle(
                  label: '显示隐干',
                  subtitle: 'showYinGan',
                  value: _showYinGan,
                  onChanged: (v) => setState(() => _showYinGan = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggle(
                  label: '显示暗干',
                  subtitle: 'showAnGan',
                  value: _showAnGan,
                  onChanged: (v) => setState(() => _showAnGan = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(), // Placeholder for alignment
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: Animations.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? ColorSystem.primary.withValues(alpha: 0.08)
              : ColorSystem.surfaceVariant,
          borderRadius: QiMenRadius.sm,
          border: Border.all(
            color: value ? ColorSystem.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: QiMenTypography.labelMedium.copyWith(
                      color: ColorSystem.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: QiMenTypography.labelMedium.copyWith(
                      color: ColorSystem.textTertiary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: ColorSystem.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // ── 尺寸切换 ────────────────────────────────────────────────────────────────

  Widget _buildSizePicker() {
    return Row(
      children: List.generate(_sizePresets.length, (i) {
        final preset = _sizePresets[i];
        final selected = i == _selectedSizeIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSizeIndex = i),
              child: AnimatedContainer(
                duration: Animations.durationFast,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? ColorSystem.primary
                      : ColorSystem.surfaceVariant,
                  borderRadius: QiMenRadius.sm,
                ),
                child: Text(
                  preset.label,
                  textAlign: TextAlign.center,
                  style: QiMenTypography.labelMedium.copyWith(
                    color: selected ? Colors.white : ColorSystem.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── 选中宫位详情 ────────────────────────────────────────────────────────────

  Widget _buildSelectedInfo() {
    final data = PalaceData.generateSampleData()[_selectedPalaceIndex!];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorSystem.surfaceVariant,
        borderRadius: QiMenRadius.md,
        border: Border.all(color: ColorSystem.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: ColorSystem.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${data.name}（${data.number}宫）',
                style: QiMenTypography.labelLarge.copyWith(
                  color: ColorSystem.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedPalaceIndex = null),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: ColorSystem.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _infoChip(
                '九星',
                data.star,
                TraditionalColors.getJiuXingColor(data.star),
              ),
              _infoChip(
                '八门',
                data.door,
                TraditionalColors.getBaMenColor(data.door),
              ),
              _infoChip('天盘八神', data.god, ColorSystem.accent),
              _infoChip('地盘八神', data.diGod, ColorSystem.textSecondary),
              _infoChip(
                '天盘干',
                data.tianPanGan,
                TraditionalColors.getGanColor(data.tianPanGan),
              ),
              _infoChip(
                '地盘干',
                data.diPanGan,
                TraditionalColors.getGanColor(data.diPanGan),
              ),
            ],
          ),
          if (data.marks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: data.marks
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ColorSystem.accent.withValues(alpha: 0.1),
                        borderRadius: QiMenRadius.sm,
                      ),
                      child: Text(
                        m,
                        style: QiMenTypography.labelMedium.copyWith(
                          color: ColorSystem.accent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (data.yinGan != null || data.tianPanAnGan != null) ...[
            const SizedBox(height: 8),
            Text(
              '隐/暗干: ${[if (data.yinGan != null) '隐干 ${data.yinGan}', if (data.tianPanAnGan != null) '天盘暗干 ${data.tianPanAnGan}'].join(' · ')}',
              style: QiMenTypography.labelMedium.copyWith(
                color: ColorSystem.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: QiMenTypography.labelMedium.copyWith(
            color: ColorSystem.textSecondary,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: QiMenTypography.labelMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ── 布局说明 ────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorSystem.surface,
        borderRadius: QiMenRadius.md,
        border: Border.all(
          color: ColorSystem.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '简介模式布局说明',
            style: QiMenTypography.labelMedium.copyWith(
              color: ColorSystem.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _legendRow('左列 35%', '天盘八神 / 九星 / 八门 / 地八神（可选）'),
          _legendRow('中列 30%', '天盘干（大字）/ 分割线 / 地盘干（大字）'),
          _legendRow('右列 35%', '驿马动画（条件）/ 空亡圆圈（条件）/ 隐干（可选）'),
          const SizedBox(height: 6),
          Text(
            '标记含「驿马」的宫位显示马动画，含「空亡」的显示空心圈。',
            style: QiMenTypography.labelMedium.copyWith(
              color: ColorSystem.textTertiary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              title,
              style: QiMenTypography.labelMedium.copyWith(
                color: ColorSystem.primary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: QiMenTypography.labelMedium.copyWith(
                color: ColorSystem.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizePreset {
  final String label;
  final int gridSize;
  const _SizePreset(this.label, this.gridSize);
}
