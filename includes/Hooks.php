<?php
/**
 * @file
 * @license GPL-3.0-or-later
 */

namespace MediaWiki\Extension\Discourse;

/**
 * Discourse extension hooks.
 */
class Hooks implements
	\MediaWiki\Extension\Scribunto\Hooks\ScribuntoExternalLibrariesHook
{

	/**
	 * @link https://www.mediawiki.org/wiki/Extension:Scribunto/Hooks/ScribuntoExternalLibraries
	 * @param string $engine
	 * @param string[] &$libs
	 */
	public function onScribuntoExternalLibraries( string $engine, array &$libs ) {
		if ( $engine === 'lua' ) {
			$libs['mw.ext.discourse'] = DiscourseLuaLibrary::class;
		}
	}
}
