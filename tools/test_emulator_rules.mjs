import assert from 'node:assert/strict';

const projectId = 'demo-entrelinhas';
const authBase = 'http://127.0.0.1:9099';
const firestoreBase = 'http://127.0.0.1:8080/v1';
const database = `projects/${projectId}/databases/(default)`;

async function request(url, method = 'GET', token, body) {
  const response = await fetch(url, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const text = await response.text();
  return { status: response.status, body: text ? JSON.parse(text) : null };
}

async function signIn() {
  const response = await request(
    `${authBase}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    'POST',
    undefined,
    { returnSecureToken: true },
  );
  assert.equal(response.status, 200, JSON.stringify(response.body));
  return { uid: response.body.localId, token: response.body.idToken };
}

const owner = await signIn();
const other = await signIn();
const bookId = `rules-test-${Date.now()}`;
const name = `${database}/documents/users/${owner.uid}/books/${bookId}`;
const documentUrl = `${firestoreBase}/${name}`;
const commitUrl = `${firestoreBase}/${database}/documents:commit`;
const fields = {
  title: { stringValue: 'Livro de integração das regras' },
  author: { stringValue: 'Autora de teste' },
  totalPages: { integerValue: '240' },
  genre: { stringValue: 'Ficção' },
  currentPage: { integerValue: '0' },
  status: { stringValue: 'wantToRead' },
  notes: { stringValue: '' },
};
const timestamps = [
  { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
  { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
];

let exists = false;
try {
  const invalid = await request(commitUrl, 'POST', owner.token, {
    writes: [{
      update: { name, fields: { ...fields, currentPage: { integerValue: '241' } } },
      updateTransforms: timestamps,
      currentDocument: { exists: false },
    }],
  });
  if (invalid.status === 200) exists = true;
  assert.equal(invalid.status, 403, JSON.stringify(invalid.body));

  for (const coverUrl of [
    'http://example.com/capa.jpg',
    'https://user:password@example.com/capa.jpg',
    'https://user@example.com/capa.jpg',
  ]) {
    const invalidCover = await request(commitUrl, 'POST', owner.token, {
      writes: [{
        update: { name, fields: { ...fields, coverUrl: { stringValue: coverUrl } } },
        updateTransforms: timestamps,
        currentDocument: { exists: false },
      }],
    });
    if (invalidCover.status === 200) exists = true;
    assert.equal(invalidCover.status, 403, `Invalid cover URL accepted: ${coverUrl}`);
  }

  const created = await request(commitUrl, 'POST', owner.token, {
    writes: [{
      update: { name, fields },
      updateTransforms: timestamps,
      currentDocument: { exists: false },
    }],
  });
  assert.equal(created.status, 200, JSON.stringify(created.body));
  exists = true;

  const initial = await request(documentUrl, 'GET', owner.token);
  assert.equal(initial.status, 200, JSON.stringify(initial.body));
  assert.equal(initial.body.fields.title.stringValue, fields.title.stringValue);
  // A pre-existing document without the optional field must remain valid.
  assert.equal(Object.hasOwn(initial.body.fields, 'coverUrl'), false);

  const anonymousRead = await request(documentUrl);
  assert.equal(anonymousRead.status, 403, JSON.stringify(anonymousRead.body));
  const foreignRead = await request(documentUrl, 'GET', other.token);
  assert.equal(foreignRead.status, 403, JSON.stringify(foreignRead.body));
  const foreignDelete = await request(documentUrl, 'DELETE', other.token);
  assert.equal(foreignDelete.status, 403, JSON.stringify(foreignDelete.body));

  const updated = await request(commitUrl, 'POST', owner.token, {
    writes: [{
      update: {
        name,
        fields: {
          title: { stringValue: 'Livro editado' },
          currentPage: { integerValue: '80' },
          status: { stringValue: 'reading' },
          coverUrl: { stringValue: 'https://example.com/capa%20azul.jpg?size=300' },
        },
      },
      updateMask: { fieldPaths: ['title', 'currentPage', 'status', 'coverUrl'] },
      updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: true },
    }],
  });
  assert.equal(updated.status, 200, JSON.stringify(updated.body));
  const persisted = await request(documentUrl, 'GET', owner.token);
  assert.equal(persisted.status, 200, JSON.stringify(persisted.body));
  assert.equal(persisted.body.fields.title.stringValue, 'Livro editado');
  assert.equal(persisted.body.fields.currentPage.integerValue, '80');
  assert.equal(persisted.body.fields.status.stringValue, 'reading');
  assert.equal(
    persisted.body.fields.coverUrl.stringValue,
    'https://example.com/capa%20azul.jpg?size=300',
  );
  assert.equal(
    persisted.body.fields.createdAt.timestampValue,
    initial.body.fields.createdAt.timestampValue,
  );

  const invalidCoverEdit = await request(commitUrl, 'POST', owner.token, {
    writes: [{
      update: {
        name,
        fields: { coverUrl: { stringValue: 'http://example.com/capa.jpg' } },
      },
      updateMask: { fieldPaths: ['coverUrl'] },
      updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: true },
    }],
  });
  assert.equal(invalidCoverEdit.status, 403, JSON.stringify(invalidCoverEdit.body));

  const removedCover = await request(commitUrl, 'POST', owner.token, {
    writes: [{
      update: { name, fields: { coverUrl: { stringValue: '' } } },
      updateMask: { fieldPaths: ['coverUrl'] },
      updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
      currentDocument: { exists: true },
    }],
  });
  assert.equal(removedCover.status, 200, JSON.stringify(removedCover.body));
  const withoutCover = await request(documentUrl, 'GET', owner.token);
  assert.equal(withoutCover.status, 200, JSON.stringify(withoutCover.body));
  assert.equal(withoutCover.body.fields.coverUrl.stringValue, '');
  assert.equal(withoutCover.body.fields.title.stringValue, 'Livro editado');
  assert.equal(withoutCover.body.fields.currentPage.integerValue, '80');
  assert.equal(
    withoutCover.body.fields.createdAt.timestampValue,
    initial.body.fields.createdAt.timestampValue,
  );

  const deleted = await request(documentUrl, 'DELETE', owner.token);
  assert.equal(deleted.status, 200, JSON.stringify(deleted.body));
  exists = false;
  const missing = await request(documentUrl, 'GET', owner.token);
  assert.equal(missing.status, 404, JSON.stringify(missing.body));
  console.log('PASS: CRUD real, capa opcional HTTPS, timestamps, validação, isolamento por usuário e bloqueio sem autenticação.');
} finally {
  if (exists) await request(documentUrl, 'DELETE', owner.token);
}
