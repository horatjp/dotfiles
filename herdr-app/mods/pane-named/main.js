// どこ: dotfiles/herdr-app/mods/pane-named(install.sh が ~/.config/herdr-app/mods/pane-named へリンクする)
// 何: ペインの見出し。Herdr 同梱の pane mod の写しで、端末の名前(hc run --name・terminal.open {name})か
//   ラベル role(hc label <t> role=<役>)があれば、それを先頭に太字で出す。どちらも無ければ同梱の pane と同じ表示。
// なぜ: 同梱の pane は PaneInfo(プログラム名・タイトル)しか見ず、hc の名前を出さない。マルチエージェントで
//   どのペインが何の役かを見分けるため。名前は開くときにしか付けられないので、あとから付け直せる role も読む。
// 使い方: レイアウトの "header": { "content": { "mod": "pane-named" } }(layouts/mine.json)。
// アイコンは同梱の mods/pane/*.svg をそのまま使う(同梱の mod は Herdr が置き直すので消えない)。

import { View, div, svg, image } from "gpui-kit";
import { h_flex } from "gpui-base";
import { panes, props, run, theme, home, terminals } from "herdr";

function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

function folder(cwd) {
  if (!cwd) return "";
  const h = home();
  return cwd === h ? "~" : cwd.startsWith(h + "/") ? "~" + cwd.slice(h.length) : cwd;
}

// 端末の名前、無ければラベル role。別マシンの端末は address に machine/ が付かないことがあるので末尾でも照合する
function roleOf(terminal) {
  if (!terminal) return null;
  const short = terminal.includes("/") ? terminal.slice(terminal.lastIndexOf("/") + 1) : terminal;
  const t = (terminals() || []).find((x) => x?.address === terminal || x?.address === short);
  return t?.name || t?.labels?.role || null;
}

export default class PaneNamed extends View {
  init() { this.hovered = false; }

  me() {
    return panes().find((p) => p.pane === props()?.pane);
  }

  button(t, id, icon, command, args) {
    return div()
      .id(id)
      .p(3)
      .rounded(4)
      .text_color(t.dim)
      .hover((s) => s.bg(t.hover).text_color(t.foreground))
      .on_click((_e, cx) => {
        cx.stop_propagation();
        run(command, args);
      })
      .child(svg(`mods/pane/${icon}.svg`).size(14));
  }

  render(cx) {
    const t = theme();
    const p = this.me();
    if (!p) return div();
    const name = ((p.program?.agent || p.program?.shell) && p.program.name) || p.title || p.program?.name || "shell";
    const role = roleOf(p.terminal ?? props()?.terminal);
    const pic = icon(p.program, 14, t.dim);
    const st = p.status;
    const pane = p.pane;
    return h_flex()
      .id(`pane-head-${pane}`)
      .size_full()
      .px(10)
      .gap(8)
      .items_center()
      .bg(t.background)
      .border_b(1)
      .border_color(t.border)
      .text_size(12)
      .on_hover((hovered, cx) => { this.hovered = hovered; cx.notify(); })
      .on_click(() => run("pane.focus", { pane }))
      .when(Boolean(role), (el) => el.child(div().flex_none().truncate().max_w(200).font_semibold().text_color(t.accent).child(role)))
      .when(Boolean(pic), (el) => el.child(pic))
      .child(div().flex_none().truncate().max_w(260).font_medium().text_color(role ? t.dim : t.foreground).child(name))
      .child(div().flex_1().truncate().text_color(t.dim).child(folder(p.cwd)))
      .when(st === "working", el => el.child(svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900)))
      .when(st === "blocked", el => el.child(div().flex_none().px(6).h(18).flex().items_center().rounded(5).bg(t.blocked + "26").text_size(10.5).font_semibold().text_color(t.blocked).child("Needs you")))
      .when(st === "done", el => el.child(div().size(7).flex_none().rounded(4).bg(t.done)))
      .when(this.hovered, el => el
        .child(this.button(t, `ph-r-${pane}`, "split-right", "pane.split", { direction: "right", pane }))
        .child(this.button(t, `ph-d-${pane}`, "split-down", "pane.split", { direction: "down", pane }))
        .child(this.button(t, `ph-z-${pane}`, p.zoomed ? "unzoom" : "zoom", "pane.zoom", { pane }))
        .child(this.button(t, `ph-x-${pane}`, "close", "pane.close", { pane })));
  }
}
