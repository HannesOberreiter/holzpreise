/**
 * Bunny Edge Script for www.holzpreise.at
 *
 * Provides a small cached proxy for public data sources that are flaky from
 * GitHub Actions. The website still documents the official source URLs; this
 * proxy is only an operational fallback for CI/data refreshes.
 */

import * as BunnySDK from "https://esm.sh/@bunny.net/edgescript-sdk@0.11.2";

const proxiedDataSources: Record<string, string> = {
  "/_data/statistik/vpi76.csv": "https://data.statistik.gv.at/data/OGD_vpi76_VPI_1976_1.csv",
  "/_data/statistik/vpi20-coicop18.csv": "https://data.statistik.gv.at/data/OGD_vpi20c18_VPI_2020COICOP18_1.csv",
  "/_data/statistik/epi2021-oecpa.csv": "https://data.statistik.gv.at/data/OGD_epi2021cpa15_EPI_2021_OECPA_1.csv",
  "/_data/statistik/ghpi2020.csv": "https://data.statistik.gv.at/data/OGD_pregpi003_GHPI_20_1.csv",
};

async function proxyDataSource(sourceUrl: string): Promise<Response> {
  const upstream = await fetch(sourceUrl, {
    headers: {
      "User-Agent": "holzpreise.at-data-proxy",
      "Accept": "text/csv,*/*;q=0.8",
    },
  });

  if (!upstream.ok) {
    return new Response(`Upstream fetch failed: ${upstream.status}`, { status: 502 });
  }

  const headers = new Headers(upstream.headers);
  headers.set("Cache-Control", "public, max-age=86400, stale-while-revalidate=604800");
  headers.set("Content-Type", "text/csv; charset=utf-8");
  headers.set("X-Holzpreise-Source", sourceUrl);

  return new Response(upstream.body, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers,
  });
}

async function onOriginRequest(
  context: { request: Request },
): Promise<Response> | Response | Promise<Request> | Request | void {
  const url = new URL(context.request.url);
  const sourceUrl = proxiedDataSources[url.pathname];

  if (sourceUrl) {
    return proxyDataSource(sourceUrl);
  }

  return context.request;
}

BunnySDK.net.http.servePullZone()
  .onOriginRequest(onOriginRequest);
