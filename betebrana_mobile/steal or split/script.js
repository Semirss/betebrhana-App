const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');
const scoreDisplay = document.getElementById('score');
const newGameBtn = document.getElementById('new-game-btn');
const leaderboardList = document.getElementById('leaderboard-list');
const leaderboardToggleBtn = document.getElementById('leaderboard-toggle-btn');
const leaderboardDiv = document.getElementById('leaderboard');


// Game constants
const PADDLE_WIDTH = 100;
const PADDLE_HEIGHT = 20;
const PADDLE_MARGIN_BOTTOM = 50;
const BALL_RADIUS = 8;
const BRICK_ROW_COUNT = 5;
const BRICK_COLUMN_COUNT = 9;
const BRICK_WIDTH = 75;
const BRICK_HEIGHT = 20;
const BRICK_PADDING = 10;
const BRICK_OFFSET_TOP = 30;
const BRICK_OFFSET_LEFT = 30;
const LEADERBOARD_MAX_SIZE = 5;

// Paddle object
const paddle = {
    x: (canvas.width - PADDLE_WIDTH) / 2,
    y: canvas.height - PADDLE_MARGIN_BOTTOM - PADDLE_HEIGHT,
    width: PADDLE_WIDTH,
    height: PADDLE_HEIGHT,
    dx: 8
};

// Ball object
const ball = {
    x: canvas.width / 2,
    y: paddle.y - BALL_RADIUS,
    radius: BALL_RADIUS,
    speed: 4,
    dx: 4,
    dy: -4
};

// --- Game State, Bricks, and Particles ---
let bricks = [];
let particles = [];
let score = 0;
let gameOver = false;
let gameRunning = true;

class Particle {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.radius = Math.random() * 3 + 1;
        this.color = '#f1c40f';
        this.vx = (Math.random() - 0.5) * 4;
        this.vy = (Math.random() - 0.5) * 4;
        this.alpha = 1;
    }

    draw() {
        ctx.save();
        ctx.globalAlpha = this.alpha;
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fillStyle = this.color;
        ctx.fill();
        ctx.restore();
    }

    update() {
        this.x += this.vx;
        this.y += this.vy;
        this.alpha -= 0.02;
    }
}

function createBricks() {
    bricks = [];
    for (let c = 0; c < BRICK_COLUMN_COUNT; c++) {
        bricks[c] = [];
        for (let r = 0; r < BRICK_ROW_COUNT; r++) {
            const brickX = c * (BRICK_WIDTH + BRICK_PADDING) + BRICK_OFFSET_LEFT;
            const brickY = r * (BRICK_HEIGHT + BRICK_PADDING) + BRICK_OFFSET_TOP;
            bricks[c][r] = { x: brickX, y: brickY, status: 1 };
        }
    }
}

// --- Leaderboard ---
let leaderboard = [];

function loadLeaderboard() {
    const storedScores = localStorage.getItem('brickBreakerLeaderboard');
    if (storedScores) {
        leaderboard = JSON.parse(storedScores);
    }
}

function saveLeaderboard() {
    localStorage.setItem('brickBreakerLeaderboard', JSON.stringify(leaderboard));
}

function updateLeaderboardDisplay() {
    leaderboardList.innerHTML = '';
    leaderboard.forEach(entry => {
        const li = document.createElement('li');
        li.innerHTML = `<span class="name">${entry.name}</span> <span class="score">${entry.score}</span>`;
        leaderboardList.appendChild(li);
    });
}

function addToLeaderboard(name, score) {
    leaderboard.push({ name, score });
    leaderboard.sort((a, b) => b.score - a.score);
    leaderboard = leaderboard.slice(0, LEADERBOARD_MAX_SIZE);
    saveLeaderboard();
    updateLeaderboardDisplay();
}


// --- Drawing Functions ---
function drawPaddle() {
    ctx.beginPath();
    ctx.rect(paddle.x, paddle.y, paddle.width, paddle.height);
    ctx.fillStyle = '#3498db';
    ctx.fill();
    ctx.closePath();
}

function drawBall() {
    ctx.beginPath();
    ctx.arc(ball.x, ball.y, ball.radius, 0, Math.PI * 2);
    ctx.fillStyle = '#e74c3c';
    ctx.fill();
    ctx.closePath();
}

function drawBricks() {
    bricks.forEach(column => {
        column.forEach(brick => {
            if (brick.status === 1) {
                ctx.beginPath();
                ctx.rect(brick.x, brick.y, BRICK_WIDTH, BRICK_HEIGHT);
                ctx.fillStyle = '#9b59b6';
                ctx.fill();
                ctx.strokeStyle = '#8e44ad';
                ctx.lineWidth = 2;
                ctx.stroke();
                ctx.closePath();
            }
        });
    });
}

function drawParticles() {
    for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.update();
        p.draw();
        if (p.alpha <= 0) {
            particles.splice(i, 1);
        }
    }
}

function updateScoreDisplay() {
    scoreDisplay.textContent = `Score: ${score}`;
}

function drawEndGameMessage(message) {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.font = '40px Arial';
    ctx.fillStyle = 'white';
    ctx.textAlign = 'center';
    ctx.fillText(message, canvas.width / 2, canvas.height / 2 - 20);
    ctx.font = '20px Arial';
    ctx.fillText('Click "New Game" to play again', canvas.width / 2, canvas.height / 2 + 20);
}


// --- Controls and Movement ---
let rightPressed = false;
let leftPressed = false;

document.addEventListener('keydown', e => {
    if (e.key === 'Right' || e.key === 'ArrowRight') rightPressed = true;
    else if (e.key === 'Left' || e.key === 'ArrowLeft') leftPressed = true;
});

document.addEventListener('keyup', e => {
    if (e.key === 'Right' || e.key === 'ArrowRight') rightPressed = false;
    else if (e.key === 'Left' || e.key === 'ArrowLeft') leftPressed = false;
});

function handleMove(e) {
    const relativeX = (e.clientX || e.touches[0].clientX) - canvas.getBoundingClientRect().left;
    if (relativeX > 0 && relativeX < canvas.width) {
        paddle.x = relativeX - paddle.width / 2;
        if (paddle.x < 0) paddle.x = 0;
        if (paddle.x + paddle.width > canvas.width) paddle.x = canvas.width - paddle.width;
    }
}

canvas.addEventListener('mousemove', handleMove);
canvas.addEventListener('touchmove', e => {
    e.preventDefault(); // Prevent scrolling
    handleMove(e);
}, { passive: false });


function movePaddle() {
    if (rightPressed && paddle.x < canvas.width - paddle.width) {
        paddle.x += paddle.dx;
    } else if (leftPressed && paddle.x > 0) {
        paddle.x -= paddle.dx;
    }
}

function moveBall() {
    ball.x += ball.dx;
    ball.y += ball.dy;

    if (ball.x + ball.radius > canvas.width || ball.x - ball.radius < 0) ball.dx *= -1;
    if (ball.y - ball.radius < 0) ball.dy *= -1;

    if (ball.y + ball.radius > paddle.y && ball.y - ball.radius < paddle.y + paddle.height && ball.x > paddle.x && ball.x < paddle.x + paddle.width) {
        ball.dy = -ball.speed;
    }

    bricks.forEach(column => {
        column.forEach(brick => {
            if (brick.status === 1) {
                if (ball.x > brick.x && ball.x < brick.x + BRICK_WIDTH && ball.y > brick.y && ball.y < brick.y + BRICK_HEIGHT) {
                    ball.dy *= -1;
                    brick.status = 0;
                    score++;
                    updateScoreDisplay();
                    // Create particle burst
                    for(let i = 0; i < 8; i++) {
                        particles.push(new Particle(ball.x, ball.y));
                    }
                }
            }
        });
    });

    if (score === BRICK_ROW_COUNT * BRICK_COLUMN_COUNT) {
        gameRunning = false;
        gameOver = true;
        drawEndGameMessage('YOU WIN!');
        handleGameOver();
    }

    if (ball.y + ball.radius > canvas.height) {
        gameRunning = false;
        gameOver = true;
        drawEndGameMessage('GAME OVER');
        handleGameOver();
    }
}

function handleGameOver() {
    setTimeout(() => { // Timeout to allow message to be seen
        const name = prompt('Game Over! Enter your name for the leaderboard:');
        if (name) {
            addToLeaderboard(name.trim(), score);
        }
    }, 500);
}

// --- Game Loop ---
function update() {
    if (!gameRunning) {
        return;
    }
    requestAnimationFrame(update);

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drawBricks();
    drawParticles();
    drawPaddle();
    drawBall();
    
    movePaddle();
    moveBall();
}

function resetGame() {
    createBricks();
    score = 0;
    ball.x = canvas.width / 2;
    ball.y = paddle.y - BALL_RADIUS;
    ball.dx = (Math.random() - 0.5) * 8;
    ball.dy = -4;
    paddle.x = (canvas.width - PADDLE_WIDTH) / 2;
    gameOver = false;
    gameRunning = true;
    updateScoreDisplay();
    update();
}

// --- Initialization ---
leaderboardToggleBtn.addEventListener('click', () => {
    leaderboardDiv.classList.toggle('show');
});

newGameBtn.addEventListener('click', resetGame);

loadLeaderboard();
updateLeaderboardDisplay();
createBricks();
updateScoreDisplay();
update();
