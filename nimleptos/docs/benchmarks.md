# NimLeptos Benchmarks

Performance benchmarks for the NimLeptos reactive framework.

## Running Benchmarks

```bash
nimble benchSignal    # Signal update throughput
nimble benchDom       # DOM node tree construction and rendering
nimble benchSsr       # SSR renderFullPage throughput
nimble bench          # Run all benchmarks
```

## Signal Update Throughput (`benchmarks/signal_bench.nim`)

Measures reactive signal update performance with 10 000 iterations.

| Scenario                  | Typical Performance        |
|---------------------------|----------------------------|
| Bare signal update        | ~40M updates/s             |
| Signal + effect tracking  | ~820K updates/s            |
| Signal + memo (2 sources) | ~300K updates/s            |
| Batched (x100)            | ~2.6M updates/s (3.2x vs effect) |

**Key insight:** Batching provides 3-4x throughput improvement by deferring effect runs.

## DOM Render (`benchmarks/dom_render_bench.nim`)

Measures HtmlNode tree construction and HTML string rendering.

| Scenario                              | Performance               |
|---------------------------------------|---------------------------|
| Flat list (1000 items) — build        | ~3.8 ms                   |
| Flat list (1000 items) — renderToHtml | ~7.3 ms avg              |
| Flat list (1000 items) — renderToHtmlRaw | ~2.6 ms avg (2.8x faster) |
| Nested tree (364 nodes) — build       | ~0.2 ms                   |

**Key insight:** `renderToHtmlRaw` (no escaping) is ~2.8x faster than `renderToHtml` (with HTML escaping).

## SSR Render (`benchmarks/ssr_render_bench.nim`)

Measures server-side HTML page rendering throughput.

| Scenario                            | Performance       |
|-------------------------------------|-------------------|
| 20-item page — renderToHtml         | ~4225 renders/s   |
| 20-item page — renderToHtmlRaw      | ~2.4x faster      |
| 200-item page — single render       | ~2.4 ms           |
| 200-item page — HTML output size    | ~33K chars        |

**Key insight:** SSR rendering is fast enough for most use cases — 200 items render in ~2.4ms with HTML escaping.

## Future Comparisons

Planned benchmark comparisons:
- [ ] Karax (Nim VDOM framework) — same DOM tree, render comparison
- [ ] HappyX — SSR throughput comparison
- [ ] Leptos (Rust) — signal update throughput at same scale
