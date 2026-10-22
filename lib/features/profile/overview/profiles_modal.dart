import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilesModal extends HookConsumerWidget {
  const ProfilesModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final asyncProfiles = ref.watch(profilesNotifierProvider);

    ref.listen(profilesNotifierProvider, (_, next) {
      if (next.hasValue && next.value!.isEmpty) {
        if (context.canPop()) context.pop();
      }
    });

    final initialSize = PlatformUtils.isDesktop ? .60 : .55;
    return SafeArea(
      child: asyncProfiles.when(
        data: (data) => DraggableScrollableSheet(
          initialChildSize: initialSize,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(t.pages.profiles.title, style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    controller: scrollController,
                    separatorBuilder: (context, index) => const Gap(4),
                    itemBuilder: (context, index) => ProfileTile(key: ValueKey(data[index].id), profile: data[index]),
                    itemCount: data.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.sort_rounded),
                        label: Text(t.common.sort),
                        onPressed: () => ref.read(dialogNotifierProvider.notifier).showSortProfiles(),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.sync_rounded),
                        label: Text(t.common.update),
                        onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text(t.presentShortError(error)),
      ),
    );
  }
}
