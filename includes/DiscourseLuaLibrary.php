<?php

namespace MediaWiki\Extension\Discourse;

use MediaWiki\MediaWikiServices;
use Scribunto_LuaLibraryBase;

class DiscourseLuaLibrary extends Scribunto_LuaLibraryBase {

	/** @var string[][] */
	protected $baseUrls;

	/**
	 * Called to register the library.
	 *
	 * This should do any necessary setup and then call $this->getEngine()->registerInterface().
	 * The value returned by that call should be returned from this function,
	 * and must be for 'deferLoad' libraries to work right.
	 *
	 * @return array Lua package
	 */
	public function register(): array {
		$interfaceFuncs = [
			'getData' => [ $this, 'getData' ],
			'getBaseUrl' => [ $this, 'getBaseUrl' ],
		];
		$luaFile = dirname( __DIR__ ) . '/scribunto/discourse.lua';
		return $this->getEngine()->registerInterface( $luaFile, $interfaceFuncs );
	}

	/**
	 * Get data for a given site and URL path.
	 * @param string $site The site shortname from $wgDiscourseSites
	 * @param string $path The API URL path.
	 * @return mixed[] A result array with 'result' or 'error' key.
	 */
	public function getData( $site, $path ): array {
		$baseUrl = $this->getBaseUrl( $site );
		if ( isset( $baseUrl['error'] ) || !isset( $baseUrl['result'] ) ) {
			return [ 'error' => $baseUrl['error'] ];
		}
		if ( !$path ) {
			return [ 'error' => 'path-not-set' ];
		}
		$url = $baseUrl['result'] . '/' . ltrim( $path, '/' );
		return [ 'result' => $this->fetch( $url ) ];
	}

	/**
	 * Fetch and cache data from Discourse.
	 *
	 * @param string $url The full Discourse JSON URL.
	 * @return mixed[]
	 */
	protected function fetch( $url ): array {
		$cache = MediaWikiServices::getInstance()->getMainWANObjectCache();
		return $cache->getWithSetCallback(
			'discourse-' . md5( $url ),
			$cache::TTL_HOUR,
			function () use ( $url ) {
				$requestFactory = MediaWikiServices::getInstance()->getHttpRequestFactory();
				if ( method_exists( $requestFactory, 'request' ) ) {
					// For 1.34 and above.
					$response = $requestFactory->request( 'GET', $url );
				} else {
					// For 1.33 and below.
					$request = $requestFactory->create( $url );
					$status = $request->execute();
					$response = $status->isOK() ? $request->getContent() : false;
				}
				if ( $response ) {
					return json_decode( $response, true );
				}
				return [];
			}
		);
	}

	/**
	 * Get the base site URL (with no trailing slash).
	 *
	 * @param string $site The site shortname from $wgDiscourseSites.
	 * @return string[]
	 */
	public function getBaseUrl( $site ): array {
		$siteName = mb_strtolower( $site );
		if ( $this->baseUrls[ $siteName ] ) {
			return $this->baseUrls[ $siteName ];
		}
		$config = MediaWikiServices::getInstance()->getMainConfig();
		$sites = $config->get( 'DiscourseSites' );
		$defaultSite = $config->get( 'DiscourseDefaultSite' );
		if ( $siteName && isset( $sites[$siteName] ) ) {
			$url = $sites[ $siteName ];
		} elseif ( !$siteName && isset( $sites[ $defaultSite ] ) ) {
			$url = $sites[ $defaultSite ];
		} else {
			return [ 'error' => wfMessage( 'discourse-site-not-found', $siteName )->text() ];
		}
		$this->baseUrls[ $siteName ] = [ 'result' => rtrim( $url, '/' ) ];
		return $this->baseUrls[ $siteName ];
	}
}
