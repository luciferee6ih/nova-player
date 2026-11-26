// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_contributors.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The About screen's developer row. A fixed list (no network): the app
/// credits its developer, not everyone in the repository history.

@ProviderFor(githubContributors)
final githubContributorsProvider = GithubContributorsProvider._();

/// The About screen's developer row. A fixed list (no network): the app
/// credits its developer, not everyone in the repository history.

final class GithubContributorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GithubContributor>>,
          List<GithubContributor>,
          Stream<List<GithubContributor>>
        >
    with
        $FutureModifier<List<GithubContributor>>,
        $StreamProvider<List<GithubContributor>> {
  /// The About screen's developer row. A fixed list (no network): the app
  /// credits its developer, not everyone in the repository history.
  GithubContributorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubContributorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubContributorsHash();

  @$internal
  @override
  $StreamProviderElement<List<GithubContributor>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GithubContributor>> create(Ref ref) {
    return githubContributors(ref);
  }
}

String _$githubContributorsHash() =>
    r'c2b166a0f8c3a8376f690810f9255beba932f691';
