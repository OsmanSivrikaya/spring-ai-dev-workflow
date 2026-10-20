"""Hook'ları sahte bir proje kopyasında uçtan uca test eder (gerçek projeye dokunmaz).
Kullanım: python3 .claude/hooks/tests/hooktest.py [.claude klasörü]
CI'da da çalışır (.github/workflows/ci.yml)."""
import json, os, shutil, subprocess, sys, tempfile

CLAUDE_DIR = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", ".."))
HOOKS_SRC = f"{CLAUDE_DIR}/hooks"
BASE = tempfile.mkdtemp(prefix="hooktest-")
ROOT = f"{BASE}/proj"
CACHE = f"{BASE}/cache"
os.makedirs(f"{ROOT}/.claude/hooks")
for f in os.listdir(HOOKS_SRC):
    if f.endswith(".sh"):
        shutil.copy(f"{HOOKS_SRC}/{f}", f"{ROOT}/.claude/hooks/{f}")
shutil.copy(f"{CLAUDE_DIR}/settings.json", f"{ROOT}/.claude/settings.json")
files = {
    "pom.xml": "<project/>",
    "auth-service/pom.xml": "<project/>",
    "auth-service/src/main/java/A.java": "class A {}",
    "product-service/pom.xml": "<project/>",
    "product-service/src/main/java/P.java": "class P {}",
    "product-service/src/test/java/PTest.java": "class PTest { /* assert */ }",
    "README.md": "doc",
}
for p, c in files.items():
    os.makedirs(os.path.dirname(f"{ROOT}/{p}") or ROOT, exist_ok=True)
    open(f"{ROOT}/{p}", "w").write(c)

STATE = f"{CACHE}/claude-guard/{ROOT.replace('/', '_')}"
env = dict(os.environ, CLAUDE_PROJECT_DIR=ROOT, XDG_CACHE_HOME=CACHE, PATH="/usr/bin:/bin:/usr/sbin:/sbin")
H = f"{ROOT}/.claude/hooks"
ok = fail = 0


def run(hook, payload, e=env):
    r = subprocess.run([f"{H}/{hook}"], input=json.dumps(payload), capture_output=True, text=True, env=e, cwd=ROOT)
    return r.returncode, r.stdout, r.stderr


def check(name, cond):
    global ok, fail
    ok += cond; fail += (not cond)
    print(("OK  " if cond else "FAIL"), name)


def bash(cmd, agent=None):
    p = {"tool_name": "Bash", "tool_input": {"command": cmd}}
    if agent: p["agent_type"] = agent
    return run("agent-scope.sh", p)[0]


def write(path, agent=None):
    p = {"tool_name": "Write", "tool_input": {"file_path": path if path.startswith("/") else f"{ROOT}/{path}"}}
    if agent: p["agent_type"] = agent
    return run("agent-scope.sh", p)[0]


def st(name): return f"{STATE}/{name}"
def rm(name):
    if os.path.exists(st(name)): os.remove(st(name))


TEST = f"{ROOT}/product-service/src/test/java/PTest.java"
post_main = {"tool_name": "Bash", "tool_input": {"command": "python3 gizli_script.py"}}

print("--- Testlere yazma (önleme)")
check("main sed -i test          → engel", bash("sed -i '' 's/assert//' product-service/src/test/java/PTest.java") == 2)
check("main cat > test (heredoc) → engel", bash("cat > product-service/src/test/java/PTest.java <<EOF\nclass PTest {}\nEOF") == 2)
check("main mvn test | tail      → izin", bash("mvn -q -pl product-service test 2>&1 | tail -20") == 0)
check("main sed -i main kod      → izin", bash("sed -i '' 's/A/B/' auth-service/src/main/java/A.java") == 0)
check("main Write test dosyası   → engel", write("product-service/src/test/java/PTest.java") == 2)
check("test-engineer Write test  → izin", write("product-service/src/test/java/PTest.java", "test-engineer") == 0)
check("test-engineer Write main  → engel", write("product-service/src/main/java/P.java", "test-engineer") == 2)
check("code-reviewer echo > x    → engel", bash("echo x > a.txt", "code-reviewer") == 2)

print("--- Tehlikeli komutlar ve yanlış pozitifler (madde 4)")
for c in ["rm -rf target", "rm -fr target", "rm -r -f target", "rm --recursive --force target"]:
    check(f"{c:30} → engel", bash(c) == 2)
check("rm -f tek.txt                  → izin", bash("rm -f tek.txt") == 0)
check("git -C . push origin main      → engel", bash("git -C . push origin main") == 2)
check("git -c user.name=x push        → engel", bash("git -c user.name=x push") == 2)
check("git status && git push         → engel", bash("git status && git push") == 2)
check("git reset --hard HEAD~1        → engel", bash("git reset --hard HEAD~1") == 2)
check("git log --grep push            → izin", bash("git log --grep push") == 0)
check("git commit -m 'push fix'       → izin", bash("git commit -m 'push fix'") == 0)
check("git reset HEAD dosya           → izin", bash("git reset HEAD README.md") == 0)
check("cat .env                       → engel", bash("cat .env") == 2)
check("cat product-service/.env.local → engel", bash("cat product-service/.env.local") == 2)
check("cat .env.example               → izin", bash("cat .env.example") == 0)
check("cp .env.example .env           → engel", bash("cp .env.example .env") == 2)
check("printenv HOME                  → izin", bash("printenv HOME") == 0)

print("--- Bekçinin kendi dosyaları (madde 2)")
check("main Write .claude/hooks/x.sh       → engel", write(".claude/hooks/agent-scope.sh") == 2)
check("main Write .claude/settings.json    → engel", write(".claude/settings.json") == 2)
check("main Write durum klasörü            → engel", write(f"{STATE}/test-baseline") == 2)
check("main fp_tests > .claude/state/...   → engel", bash("fp_tests > .claude/state/test-baseline") == 2)
check("main echo > ~/.cache/claude-guard/x → engel", bash("echo x > ~/.cache/claude-guard/x/test-baseline") == 2)
check("main sed -i .claude/settings.json   → engel", bash("sed -i '' 's/a/b/' .claude/settings.json") == 2)
check("main cat .claude/settings.json      → izin", bash("cat .claude/settings.json") == 0)
run("snapshot.sh", {"source": "startup"})
check("snapshot bekçi referansını aldı", os.path.exists(st("guard-baseline")))
with open(f"{H}/agent-scope.sh", "a") as f: f.write("\nexit 0  # ajanın script üzerinden eklediği satır\n")
_, out, _ = run("test-gate.sh", {})
check("script ile değiştirilen hook test-gate'te yakalanır", '"decision": "block"' in out and "bekçi" in out)
rm("test-gate-attempts")
shutil.copy(f"{HOOKS_SRC}/agent-scope.sh", f"{H}/agent-scope.sh")  # geri al
_, out, _ = run("test-gate.sh", {})
check("geri alınınca bekçi kontrolü geçer", "bekçi" not in out)

print("--- Test değişikliği tespiti (sonuca bakan kontrol)")
run("snapshot.sh", {"source": "startup"})
open(TEST, "w").write("class PTest {}")  # testi bir script ile gevşet
_, out, _ = run("test-guard.sh", post_main)
check("test-guard tespit eder", '"decision": "block"' in out and os.path.exists(st("test-tamper")))
run("mark-changed.sh", post_main)
check("mark-changed Bash değişikliğini yakalar", open(st("changed-modules")).read().split() == ["product-service"])
_, out, _ = run("test-gate.sh", {})
check("test-gate tamper varken engeller", '"decision": "block"' in out and "test-engineer dışında" in out)
rm("test-gate-attempts")

print("--- Compact/resume sonrası iz silinmemeli (madde 1)")
settings = json.load(open(f"{ROOT}/.claude/settings.json"))
check("SessionStart matcher = startup", settings["hooks"]["SessionStart"][0].get("matcher") == "startup")
run("snapshot.sh", {"source": "startup"})  # yeni oturum bile olsa
check("yeni oturumda tamper işareti silinmez", os.path.exists(st("test-tamper")))
run("test-guard.sh", post_main)
check("gevşetilmiş test referans olmaz (işaret duruyor)", os.path.exists(st("test-tamper")))
open(TEST, "w").write("class PTest { /* assert */ }")  # geri al
run("test-guard.sh", post_main)
check("test geri alınınca işaret kalkar", not os.path.exists(st("test-tamper")))
open(TEST, "w").write("class PTest { /* yeni test */ }")
run("test-guard.sh", {"tool_name": "Write", "agent_type": "test-engineer", "tool_input": {}})
check("test-engineer değişikliği yeni referans olur", not os.path.exists(st("test-tamper")))

print("--- Hash aracı yoksa sessizce kapanmamalı (madde 3)")
nohash = f"{BASE}/nohash-bin"
os.makedirs(nohash)
for tool in ["bash", "cat", "jq", "find", "sort", "xargs", "cut", "date", "mkdir", "rm", "grep", "paste", "dirname"]:
    src = shutil.which(tool, path="/usr/bin:/bin:/usr/sbin:/sbin")
    os.symlink(src, f"{nohash}/{tool}")
env_nohash = dict(env, PATH=nohash)
rm("test-gate-attempts")
_, out, _ = run("test-gate.sh", {}, env_nohash)
check("hash aracı yoksa test-gate engeller", '"decision": "block"' in out and "hash aracı" in out)
rm("changed-modules")
run("mark-changed.sh", post_main, env_nohash)
check("hash aracı yoksa tüm modüller işaretlenir", sorted(open(st("changed-modules")).read().split()) == ["auth-service", "product-service"])

print("--- test-gate sınırları")
rm("test-gate-attempts"); rm("changed-modules")
open(st("test-tamper"), "w").write("agent=main tool=Bash")
outs = [run("test-gate.sh", {})[1] for _ in range(4)]
check("ilk 3 deneme engellenir", all('"decision": "block"' in o for o in outs[:3]))
check("4. denemede uyarıyla bırakır", '"systemMessage"' in outs[3] and "bitmiş sayılmaz" in outs[3])
rm("test-tamper")
open(st("changed-modules"), "w").write("product-service\n")
_, out, _ = run("test-gate.sh", {})
check("JDK/Maven yoksa 'doğrulanmadı' der, engellemez", "ÇALIŞTIRILAMADI" in out and "decision" not in out)
run("mark-changed.sh", post_main); rm("changed-modules")
open(f"{ROOT}/README.md", "w").write("doc 2")
run("mark-changed.sh", post_main)
check("sadece doküman değişince modül işaretlenmez", not os.path.exists(st("changed-modules")))

print(f"\n{ok} geçti, {fail} kaldı")
shutil.rmtree(BASE, ignore_errors=True)
sys.exit(1 if fail else 0)
