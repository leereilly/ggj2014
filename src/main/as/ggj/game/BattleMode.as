//
// ggj

package ggj.game {

import aspire.util.Log;

import flash.ui.Keyboard;

import flashbang.core.AppMode;
import flashbang.core.Flashbang;
import flashbang.core.GameObjectBase;
import flashbang.input.KeyboardState;
import flashbang.layout.HLayoutSprite;

import ggj.GGJ;
import ggj.debug.ParamEditor;
import ggj.game.control.PlayerControl;
import ggj.game.object.ActiveBoardMgr;
import ggj.game.object.Actor;
import ggj.game.object.GameState;
import ggj.game.object.GameStateMgr;
import ggj.game.object.Hud;
import ggj.game.object.Team;
import ggj.game.object.Tile;
import ggj.util.FeathersMgr;

import starling.display.Quad;

public class BattleMode extends AppMode
{
    public function BattleMode (numPlayers :int, params :Params = null, scoreboard :Scoreboard = null) {
        _ctx = new BattleCtx(numPlayers, params || new Params(), scoreboard || new Scoreboard());
    }

    override protected function registerObject (obj :GameObjectBase) :void {
        if (obj is AutoCtx) {
            AutoCtx(obj).setCtx(_ctx);
        }
        super.registerObject(obj);
    }

    override protected function setup () :void {
        modeSprite.addChild(new Quad(Flashbang.stageWidth, Flashbang.stageHeight, BG_COLOR));

        addObject(_ctx);

        // input
        _keyboardState = new KeyboardState();
        this.keyboardInput.registerListener(_keyboardState);

        // layers
        _modeSprite.addChild(_ctx.boardLayer);
        _modeSprite.addChild(_ctx.uiLayer);
        _modeSprite.addChild(_ctx.debugLayer);

        // controller objects
        addObject(_ctx.stateMgr = new GameStateMgr());
        addObject(_ctx.boardMgr = new ActiveBoardMgr());
        addObject(new Hud(_ctx.boardMgr));

        // actors
        var spawnTile :Tile = _ctx.boardMgr.activeBoard.spawnTile;
        for (var ii :int = 0; ii < _ctx.numPlayers; ii++) {
            var left :uint  = CONTROLS[0 + ii * 4];
            var right :uint = CONTROLS[1 + ii * 4];
            var jump :uint  = CONTROLS[2 + ii * 4];
            var power :uint = CONTROLS[3 + ii * 4];
            addObject(new Actor(Team.values()[ii], _ctx.playerColors[ii], spawnTile.x + (ii * 0.25),
                spawnTile.y, new PlayerControl(left, right, jump, power, _keyboardState)));
        }

        // parameter editing
        if (GGJ.DEBUG) {
            addObject(new FeathersMgr());
            var debugLayout :HLayoutSprite = new HLayoutSprite();
            _ctx.debugLayer.addChild(debugLayout);
            addObject(new ParamEditor(_ctx.params, "gravity"), debugLayout);
            addObject(new ParamEditor(_ctx.params, "jumpImpulse"), debugLayout);
            addObject(new ParamEditor(_ctx.params, "maxFallSpeed"), debugLayout);
            addObject(new ParamEditor(_ctx.params, "moveAccel"), debugLayout);
            addObject(new ParamEditor(_ctx.params, "moveDecel"), debugLayout);
            addObject(new ParamEditor(_ctx.params, "maxMoveSpeed"), debugLayout);
            debugLayout.layout();
            debugLayout.y = Flashbang.stageHeight - debugLayout.height - 2;
        }
    }

    override protected function update (dt :Number) :void {
        var totalDt :Number = dt;
        while (dt > 0 && !_ctx.stateMgr.isGameOver) {
            var thisDt :Number = Math.min(dt, GGJ.FRAMERATE);
            super.update(thisDt);
            dt -= thisDt;
        }

        if (_ctx.stateMgr.isGameOver) {
            var winningTeam :Team;
            if (_ctx.stateMgr.state == GameState.HAS_WINNER) {
                _ctx.scoreboard.incrementScore(_ctx.stateMgr.winner.team);
                if (_ctx.scoreboard.getScore(_ctx.stateMgr.winner.team) >= GGJ.WIN_SCORE) {
                    winningTeam = _ctx.stateMgr.winner.team;
                }
            }

            if (winningTeam == null) {
                _viewport.changeMode(new BattleMode(_ctx.numPlayers, _ctx.params, _ctx.scoreboard));
            } else {
                _viewport.pushMode(new GameOverMode(winningTeam));
            }

        } else {
            _ctx.boardMgr.updateActiveBoard(totalDt);
        }
    }

    // per player: left move, right move, jump, power
    protected static const CONTROLS :Vector.<uint> = new <uint>[
        Keyboard.A,    Keyboard.D,    Keyboard.W,   Keyboard.S,    // player 1
        Keyboard.F,    Keyboard.H,     Keyboard.T,  Keyboard.G,    // player 2
        Keyboard.J,    Keyboard.L,     Keyboard.I,  Keyboard.K,    // player 3
        Keyboard.LEFT, Keyboard.RIGHT, Keyboard.UP, Keyboard.DOWN  // player 4
    ];

    protected static const BG_COLOR :uint = 0x19242A;

    protected var _ctx :BattleCtx;
    protected var _keyboardState :KeyboardState;

    protected static const log :Log = Log.getLog(BattleMode);
}
}
