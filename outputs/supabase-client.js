/**
 * Sonora Cloud Adapter
 *
 * Supabaseとの通信をこのファイルへ集約します。UIはSonoraCloudだけを呼び、
 * Supabase固有の処理をindex.htmlへ広げないことが目的です。
 */
(() => {
  const config = window.SONORA_SUPABASE_CONFIG || {};
  const configured = Boolean(config.url && config.publishableKey);
  const libraryReady = Boolean(window.supabase?.createClient);
  const client = configured && libraryReady
    ? window.supabase.createClient(config.url, config.publishableKey, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true
        }
      })
    : null;

  function requireClient() {
    if (!client) throw new Error('Supabase is not configured.');
    return client;
  }

  function throwIfError(result) {
    if (result.error) throw result.error;
    return result.data;
  }

  async function getUser() {
    if (!client) return null;
    const { data, error } = await client.auth.getUser();
    if (error) return null;
    return data.user;
  }

  function onAuthStateChange(callback) {
    if (!client) return { unsubscribe() {} };
    const { data } = client.auth.onAuthStateChange((_event, session) => callback(session?.user || null));
    return data.subscription;
  }

  async function signUp({ email, password, displayName }) {
    const data = throwIfError(await requireClient().auth.signUp({
      email,
      password,
      options: {
        data: { display_name: displayName },
        emailRedirectTo: `${location.origin}${location.pathname}`
      }
    }));
    return data;
  }

  async function signIn({ email, password }) {
    return throwIfError(await requireClient().auth.signInWithPassword({ email, password }));
  }

  async function signOut() {
    return throwIfError(await requireClient().auth.signOut({ scope: 'local' }));
  }

  function safeExtension(blob) {
    const subtype = (blob.type || 'audio/webm').split('/')[1]?.split(';')[0] || 'webm';
    return subtype.replace(/[^a-z0-9]/gi, '') || 'webm';
  }

  async function uploadAudio(blob, folder = 'uploads') {
    const user = await getUser();
    if (!user) throw new Error('音声のアップロードにはログインが必要です。');
    const path = `${user.id}/${folder}/${crypto.randomUUID()}.${safeExtension(blob)}`;
    throwIfError(await requireClient().storage.from('audio-private').upload(path, blob, {
      contentType: blob.type || 'audio/webm',
      cacheControl: '3600',
      upsert: false
    }));
    return path;
  }

  async function createSignedAudioUrl(path, expiresIn = 3600) {
    const data = throwIfError(await requireClient().storage
      .from('audio-private')
      .createSignedUrl(path, expiresIn));
    return data.signedUrl;
  }

  async function createVoicePost({ title, tags = [], audioBlob }) {
    const user = await getUser();
    if (!user) throw new Error('投稿にはログインが必要です。');
    const audioPath = await uploadAudio(audioBlob, 'voice-posts');
    const data = throwIfError(await requireClient()
      .from('voice_posts')
      .insert({ user_id: user.id, title, tags, audio_path: audioPath })
      .select()
      .single());
    return data;
  }

  async function listVoicePosts() {
    const rows = throwIfError(await requireClient()
      .from('voice_posts')
      .select('id,title,tags,audio_path,downloads,created_at,profiles(display_name)')
      .eq('visibility', 'public')
      .order('downloads', { ascending: false })
      .limit(100));
    return Promise.all(rows.map(async row => ({
      ...row,
      audioUrl: await createSignedAudioUrl(row.audio_path)
    })));
  }

  async function createRequest(payload) {
    const user = await getUser();
    if (!user) throw new Error('募集にはログインが必要です。');
    const audioPath = await uploadAudio(payload.audioBlob, 'requests');
    return throwIfError(await requireClient()
      .from('requests')
      .insert({
        user_id: user.id,
        kind: payload.kind,
        title: payload.title,
        detail: payload.detail,
        amount: payload.amount || 0,
        tags: payload.tags || [],
        source_mode: payload.sourceMode,
        audio_path: audioPath
      })
      .select()
      .single());
  }

  async function listRequests() {
    const rows = throwIfError(await requireClient()
      .from('requests')
      .select('id,user_id,kind,title,detail,amount,tags,source_mode,audio_path,status,deadline,created_at,profiles(display_name)')
      .eq('status', 'open')
      .order('created_at', { ascending: false })
      .limit(100));
    return Promise.all(rows.map(async row => ({
      ...row,
      audioUrl: await createSignedAudioUrl(row.audio_path)
    })));
  }

  async function createApplication({ requestId, message, audioBlob }) {
    const user = await getUser();
    if (!user) throw new Error('応募にはログインが必要です。');
    const audioPath = await uploadAudio(audioBlob, 'applications');
    return throwIfError(await requireClient()
      .from('applications')
      .insert({
        request_id: requestId,
        user_id: user.id,
        message,
        audio_path: audioPath
      })
      .select()
      .single());
  }

  async function adoptApplication({ requestId, applicationId }) {
    const user = await getUser();
    if (!user) throw new Error('採用操作にはログインが必要です。');
    return throwIfError(await requireClient().rpc('adopt_application', {
      target_request_id: requestId,
      target_application_id: applicationId
    }));
  }

  function renderConnectionStatus() {
    const actions = document.querySelector('.nav-actions');
    if (!actions || document.querySelector('#cloudStatus')) return;
    const badge = document.createElement('span');
    badge.id = 'cloudStatus';
    badge.className = `cloud-status ${client ? 'online' : 'local'}`;
    badge.textContent = client ? 'Cloud' : 'Local';
    badge.title = client
      ? 'Supabaseへ接続しています'
      : 'Supabase未設定のため、このブラウザ内へ保存します';
    actions.prepend(badge);
  }

  window.SonoraCloud = Object.freeze({
    enabled: Boolean(client),
    client,
    getUser,
    onAuthStateChange,
    signUp,
    signIn,
    signOut,
    uploadAudio,
    createSignedAudioUrl,
    createVoicePost,
    listVoicePosts,
    createRequest,
    listRequests,
    createApplication,
    adoptApplication
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', renderConnectionStatus);
  } else {
    renderConnectionStatus();
  }
})();
