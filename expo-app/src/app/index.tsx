import { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Image } from 'expo-image';
import { addMessageListener, sendMessage, useSharedState } from 'expo-brownfield';

// Wallabag's "Reading List Inspector" RN screen — embeds inside the native
// SwiftUI app via expo-brownfield. The native side publishes the current
// reading list as shared state; this screen renders it reactively and can
// ask native to "Mark next as read" / "Sync now" via the messaging channel.
//
// Showcases the expo-image fix that landed in
// expo-brownfield@56.0.16-canary-20260526-6cd5e37: SDWebImage SPM deps are
// now bundled into the artifact, so `<Image source={{ uri: ... }} />` from
// expo-image works inside a brownfield framework.

type Article = {
  id: number;
  title: string;
  domain: string;
  thumbnail: string;
  minutes: number;
  read: boolean;
};

export default function ReadingListInspector() {
  const [unreadCount] = useSharedState<number>('unreadCount');
  const [totalCount] = useSharedState<number>('totalCount');
  const [syncStatus] = useSharedState<string>('syncStatus');
  const [lastSyncedAt] = useSharedState<string>('lastSyncedAt');
  const [articles] = useSharedState<Article[]>('articles');
  const [eventCount, setEventCount] = useState(0);

  useEffect(() => {
    const sub = addMessageListener((event) => {
      if (event?.type === 'ARTICLE_MARKED_READ' || event?.type === 'SYNC_FINISHED') {
        setEventCount((n) => n + 1);
      }
    });
    return () => sub.remove();
  }, []);

  useEffect(() => {
    // Demo auto-pulse so the recording captures the round-trip without UI automation.
    const timers = [
      setTimeout(() => sendMessage({ type: 'MARK_NEXT_READ' }), 4500),
      setTimeout(() => sendMessage({ type: 'SYNC_NOW' }), 8000),
    ];
    return () => timers.forEach(clearTimeout);
  }, []);

  return (
    <View style={styles.container}>
      <SafeAreaView style={styles.safeArea} edges={['top']}>
        <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
          <View style={styles.headerCard}>
            <Text style={styles.eyebrow}>EXPO BROWNFIELD</Text>
            <Text style={styles.title}>Reading list</Text>
            <Text style={styles.subtitle}>
              Live wallabag state shared with React Native.
            </Text>
          </View>

          <View style={styles.statsRow}>
            <Stat label="Unread" value={unreadCount != null ? `${unreadCount}` : '…'} highlight />
            <Stat label="Total" value={totalCount != null ? `${totalCount}` : '…'} />
            <Stat label="Status" value={syncStatus ?? '…'} />
          </View>

          <Text style={styles.lastSynced}>
            Last synced{' '}
            <Text style={styles.lastSyncedStrong}>{formatTime(lastSyncedAt)}</Text>
          </Text>

          <View style={styles.articleList}>
            {(articles ?? []).map((a) => (
              <ArticleRow key={a.id} article={a} />
            ))}
          </View>

          <View style={styles.buttonRow}>
            <Pressable
              onPress={() => sendMessage({ type: 'MARK_NEXT_READ' })}
              style={({ pressed }) => [styles.button, pressed && styles.buttonPressed]}
            >
              <Text style={styles.buttonText}>✓ Mark next as read</Text>
            </Pressable>
            <Pressable
              onPress={() => sendMessage({ type: 'SYNC_NOW' })}
              style={({ pressed }) => [styles.buttonSecondary, pressed && styles.buttonPressed]}
            >
              <Text style={styles.buttonSecondaryText}>↻ Sync now</Text>
            </Pressable>
          </View>

          <Text style={styles.footer}>
            Native events: <Text style={styles.footerBold}>{eventCount}</Text>
          </Text>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

function ArticleRow({ article }: { article: Article }) {
  return (
    <View style={styles.row}>
      <Image
        source={{ uri: article.thumbnail }}
        style={styles.thumb}
        contentFit="cover"
        transition={150}
      />
      <View style={styles.rowText}>
        <Text style={[styles.rowTitle, article.read && styles.rowTitleRead]} numberOfLines={2}>
          {article.title}
        </Text>
        <Text style={styles.rowMeta} numberOfLines={1}>
          {article.domain} · {article.minutes} min read
        </Text>
      </View>
      {article.read ? (
        <Text style={styles.readBadge}>read</Text>
      ) : (
        <View style={styles.unreadDot} />
      )}
    </View>
  );
}

function Stat({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  return (
    <View style={[styles.stat, highlight && styles.statHighlight]}>
      <Text style={[styles.statValue, highlight && styles.statValueHighlight]} numberOfLines={1}>
        {value}
      </Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function formatTime(iso: string | undefined) {
  if (!iso) return '…';
  try {
    return new Date(iso).toLocaleTimeString();
  } catch {
    return iso;
  }
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F5F4EF' },
  safeArea: { flex: 1 },
  scroll: { paddingHorizontal: 20, paddingTop: 16, paddingBottom: 32, gap: 16 },
  headerCard: { gap: 6 },
  eyebrow: { fontSize: 12, fontWeight: '700', letterSpacing: 1.2, color: '#6B7280' },
  title: { fontSize: 32, fontWeight: '800', color: '#1F2937' },
  subtitle: { fontSize: 14, color: '#4B5563' },
  statsRow: { flexDirection: 'row', gap: 10, marginTop: 4 },
  stat: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    paddingVertical: 14,
    paddingHorizontal: 12,
    alignItems: 'flex-start',
  },
  statHighlight: { backgroundColor: '#1F2937' },
  statValue: { fontSize: 22, fontWeight: '800', color: '#111827' },
  statValueHighlight: { color: '#F9FAFB' },
  statLabel: { fontSize: 12, fontWeight: '600', color: '#6B7280', marginTop: 4, letterSpacing: 0.6 },
  lastSynced: { fontSize: 12, color: '#6B7280' },
  lastSyncedStrong: { fontWeight: '700', color: '#1F2937' },
  articleList: { gap: 10, marginTop: 4 },
  row: {
    flexDirection: 'row',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 10,
    gap: 12,
    alignItems: 'center',
  },
  thumb: { width: 52, height: 52, borderRadius: 8, backgroundColor: '#E5E7EB' },
  rowText: { flex: 1, gap: 4 },
  rowTitle: { fontSize: 14, fontWeight: '600', color: '#111827' },
  rowTitleRead: { color: '#9CA3AF', textDecorationLine: 'line-through' },
  rowMeta: { fontSize: 12, color: '#6B7280' },
  readBadge: {
    fontSize: 10, fontWeight: '700', letterSpacing: 0.5,
    color: '#6B7280', backgroundColor: '#E5E7EB', paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999,
  },
  unreadDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: '#F59E0B' },
  buttonRow: { gap: 10, marginTop: 4 },
  button: { backgroundColor: '#111827', paddingVertical: 14, borderRadius: 12, alignItems: 'center' },
  buttonSecondary: { backgroundColor: '#F59E0B', paddingVertical: 14, borderRadius: 12, alignItems: 'center' },
  buttonPressed: { opacity: 0.85 },
  buttonText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
  buttonSecondaryText: { color: '#1F2937', fontSize: 16, fontWeight: '700' },
  footer: { textAlign: 'center', fontSize: 12, color: '#6B7280' },
  footerBold: { fontWeight: '700', color: '#1F2937' },
});
